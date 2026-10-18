import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Config.js" as Config

// Workspace OSD -- shows a giant centered number each time the focused
// workspace changes. Themed like the shell's other popups: text in accent,
// on a background card with the standard popup border, fading out after a
// short on-screen time.
//
// Preferences live in a dedicated TOML file, not shell.json:
//   ~/.config/omarchy/workspace-osd.toml   ([workspace-osd] section)
// The settings surface is opened via shell IPC:
//   omarchy-shell shell call iesta.workspace-osd openSettings
Item {
  id: root

  // Injected by the shell's panel loader (declare to receive it).
  property var shell: null
  property var manifest: null

  // ------------------------------------------------------ preferences (TOML)
  readonly property string configPath: {
    var d = Quickshell.env("XDG_CONFIG_HOME")
    return (d && d.length ? d : Quickshell.env("HOME") + "/.config") + "/omarchy/workspace-osd.toml"
  }
  property var prefs: Config.defaults()

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.prefs = Config.parse(configFile.text())
    // First run only: materialise the file so it is discoverable and hand-editable.
    onLoadFailed: configFile.setText(Config.serialize(Config.defaults()))
    onFileChanged: reload()
  }

  // Debounced save: coalesce rapid edits, then write the file back.
  Timer {
    id: saveTimer
    interval: 400
    onTriggered: configFile.setText(Config.serialize(root.prefs))
  }
  function save(delta) {
    var next = Config.defaults()
    for (var k in root.prefs) next[k] = root.prefs[k]
    for (var d in delta) next[d] = delta[d]
    // Re-parse so value types/ranges are clamped identically to file input.
    root.prefs = Config.parse(Config.serialize(next))
    saveTimer.restart()
  }
  function resetPrefs() { save(Config.defaults()) }

  // ------------------------------------------------------ settings surface IPC
  property bool settingsOpen: false
  function openSettings(arg) { root.settingsOpen = true }
  function closeSettings() { root.settingsOpen = false }

  // ------------------------------------------------------ OSD state
  readonly property int workspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
  property bool opened: false
  property string number: ""

  readonly property int cardPad: Style.space(30)
  // Asymmetric height: extra pad at the top so the glyph doesn't hug the top edge.
  readonly property int cardPadTop: Style.space(48)
  readonly property int giantSize: Math.round(Style.font.baseSize * prefs.sizeMultiplier)

  readonly property real baseWidth: Math.max(Style.space(64), Math.ceil(metrics.tightBoundingRect.width) + root.cardPad * 2)
  readonly property real baseHeight: Math.max(Style.space(88), Math.ceil(metrics.tightBoundingRect.height) + root.cardPad + root.cardPadTop)
  readonly property bool isCircle: root.prefs.shape === "circle"
  readonly property real cardWidth: root.isCircle ? Math.max(baseWidth, baseHeight) : baseWidth
  readonly property real cardHeight: root.isCircle ? Math.max(baseWidth, baseHeight) : baseHeight
  readonly property real cardRadius: root.prefs.shape === "rectangle"
    ? 0
    : (root.isCircle ? root.cardWidth / 2 : Style.cornerRadius)

  Timer {
    id: hideTimer
    interval: root.prefs.duration
    onTriggered: opened = false
  }

  // One-shot reopen after teardown so rapid workspace changes restart the
  // fade instead of fighting it.
  Timer {
    id: reopenTimer
    interval: root.prefs.reopen
    repeat: false
    onTriggered: {
      opened = true
      hideTimer.restart()
    }
  }

  function present() {
    number = String(root.workspaceId)
    opened = false
    reopenTimer.restart()
  }

  // Fires when the focused workspace changes (Hyprland connector keeps this
  // property in sync with the compositor).
  onWorkspaceIdChanged: root.present()

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "iesta-workspace-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Visual-only: keep the input region empty so the number never blocks
    // clicks to whatever is underneath it.
    mask: Region {}

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      // Borderless mode shows only the number: background fully transparent.
      color: Util.alpha(Color.background, root.prefs.border ? root.prefs.opacity : 0)
      borderSpec: root.prefs.border
        ? Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
        : Border.none()
      radius: root.cardRadius
      opacity: root.opened ? 1 : 0

      BorderSurface {
        id: ring
        visible: root.prefs.border
        anchors.fill: parent
        anchors.leftMargin: Math.max(1, Style.space(2))
        anchors.topMargin: Math.max(1, Style.space(2))
        anchors.rightMargin: Math.max(1, Style.space(2))
        anchors.bottomMargin: Math.max(1, Style.space(2))
        color: "transparent"
        borderSpec: Border.surfaceSpec("popups", "border", Util.alpha(Color.accent, 0.9), Math.max(1, Style.space(3)))
        radius: Math.max(0, root.cardRadius - Math.max(1, Style.space(2)))
        opacity: root.opened ? 1 : 0
      }

      Text {
        anchors.fill: parent
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Style.font.resolvedFamily
        font.bold: true
        font.pixelSize: root.giantSize
        text: root.number
        color: Color.accent
      }

      Behavior on opacity {
        enabled: root.opened
        id: fadeIn
        NumberAnimation { duration: root.prefs.fade; easing.type: Easing.OutCubic }
      }
    }
  }

  TextMetrics {
    id: metrics
    font.family: Style.font.resolvedFamily
    font.bold: true
    font.pixelSize: root.giantSize
    text: "00"
  }

  // Interactive settings modal, summoned over shell IPC.
  WorkspaceOsdSettings {
    open: root.settingsOpen
    prefs: root.prefs
    onClosed: root.closeSettings()
    onChanged: function (key, value) {
      var delta = {}
      delta[key] = value
      root.save(delta)
    }
    onResetRequested: root.resetPrefs()
  }
}
