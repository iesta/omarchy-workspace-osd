import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Settings surface for the Workspace OSD (OpenCode 2026-10-17).
// Interactive modal summoned via shell IPC (`openSettings`). All colours are
// Omarchy theme tokens (Color.*), and controls are qs.Ui widgets, so this
// tracks theme switches like every other shell popup.
Item {
  id: root

  property bool open: false
  property var prefs: ({})

  signal changed(string key, var value)
  signal resetRequested()
  signal closed()

  PanelWindow {
    id: win

    visible: root.open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "iesta-workspace-osd-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Scrim: click outside the card dismisses.
    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim

      MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
      }
    }

    BorderSurface {
      id: dialog

      width: Style.space(360)
      height: content.implicitHeight + Style.spacing.panelPadding * 2
      anchors.centerIn: parent
      color: Color.menu.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Style.normalBorderWidth)
      radius: Style.cornerRadius

      // Swallow clicks on empty card space so they don't reach the scrim.
      // Controls are declared after this, so they receive clicks first.
      MouseArea { anchors.fill: parent }

      PanelKeyCatcher {
        anchors.fill: parent
        onCloseRequested: root.closed()

        Column {
          id: content

          anchors.fill: parent
          anchors.margins: Style.spacing.panelPadding
          spacing: Style.spacing.xl

          Text {
            text: "Workspace OSD"
            color: Color.popups.text
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          NumberField {
            label: "On-screen time (ms)"
            value: Math.round(root.prefs.duration)
            from: 100
            to: 10000
            stepSize: 50
            onModified: function (value) { root.changed("duration", value) }
          }

          NumberField {
            label: "Fade in (ms)"
            value: Math.round(root.prefs.fade)
            from: 0
            to: 2000
            stepSize: 10
            onModified: function (value) { root.changed("fade", value) }
          }

          NumberField {
            label: "Reopen delay (ms)"
            value: Math.round(root.prefs.reopen)
            from: 0
            to: 2000
            stepSize: 10
            onModified: function (value) { root.changed("reopen", value) }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs

            Text {
              text: "Glyph size \u00d7 " + Number(root.prefs.sizeMultiplier).toFixed(1)
              color: Color.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.caption
            }

            PanelSlider {
              width: parent.width
              value: root.prefs.sizeMultiplier
              minimum: 2
              maximum: 16
              step: 0.5
              onMoved: function (value) { root.changed("sizeMultiplier", value) }
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs
            // Only meaningful with a border: borderless mode is fully transparent.
            enabled: root.prefs.border === true
            opacity: root.prefs.border === true ? 1 : 0.45

            Text {
              text: "Background opacity " + Math.round(Number(root.prefs.opacity) * 100) + "%"
              color: Color.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.caption
            }

            PanelSlider {
              width: parent.width
              value: root.prefs.opacity
              minimum: 0.05
              maximum: 1
              step: 0.01
              onMoved: function (value) { root.changed("opacity", value) }
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs

            Text {
              text: "Shape"
              color: Color.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.caption
            }

            ButtonGroup {
              options: [
                { value: "rectangle", label: "Rectangle" },
                { value: "rounded", label: "Rounded" },
                { value: "circle", label: "Circle" }
              ]
              value: root.prefs.shape
              onChanged: function (value) { root.changed("shape", value) }
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.xs
            // Corner radius only applies to the "rounded" shape.
            enabled: root.prefs.shape === "rounded"
            opacity: root.prefs.shape === "rounded" ? 1 : 0.45

            Text {
              text: "Corner roundness " + Math.round(Number(root.prefs.roundness)) + " px"
              color: Color.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.caption
            }

            PanelSlider {
              width: parent.width
              value: root.prefs.roundness
              minimum: 0
              maximum: 80
              step: 1
              onMoved: function (value) { root.changed("roundness", value) }
            }
          }

          Toggle {
            width: parent.width
            label: "Border"
            checked: root.prefs.border === true
            onClicked: root.changed("border", !root.prefs.border)
          }

          Row {
            anchors.right: parent.right
            spacing: Style.spacing.md

            Button {
              text: "Reset"
              onClicked: root.resetRequested()
            }

            Button {
              text: "Close"
              active: true
              onClicked: root.closed()
            }
          }
        }
      }
    }
  }
}
