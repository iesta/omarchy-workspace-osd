.pragma library

// Workspace OSD preferences: parse/serialize the dedicated TOML file.
// Self-contained reader for the plugin's own flat [workspace-osd] section,
// so it needs no shell internals. Values are clamped and typed here.

var SECTION = "workspace-osd"
var SHAPES = ["rectangle", "rounded", "circle"]

var DEFAULTS = {
  duration: 750,
  fade: 60,
  reopen: 0,
  sizeMultiplier: 7,
  opacity: 0.82,
  shape: "rounded",
  border: false
}

function defaults() {
  var out = {}
  for (var k in DEFAULTS) out[k] = DEFAULTS[k]
  return out
}

function clampNumber(value, lo, hi, fallback) {
  var n = Number(value)
  if (!isFinite(n)) n = fallback
  return Math.min(hi, Math.max(lo, n))
}

function parseValue(raw) {
  var v = String(raw).replace(/\s+$/, "")
  if (v.length >= 2) {
    var a = v.charAt(0)
    var b = v.charAt(v.length - 1)
    if ((a === '"' && b === '"') || (a === "'" && b === "'")) return v.slice(1, -1)
  }
  if (v === "true") return true
  if (v === "false") return false
  if (/^-?\d+(?:\.\d+)?$/.test(v)) return Number(v)
  return v
}

function applyKey(out, key, value) {
  switch (key) {
  case "duration":
    out.duration = Math.round(clampNumber(value, 100, 10000, DEFAULTS.duration)); break
  case "fade":
    out.fade = Math.round(clampNumber(value, 0, 2000, DEFAULTS.fade)); break
  case "reopen":
    out.reopen = Math.round(clampNumber(value, 0, 2000, DEFAULTS.reopen)); break
  case "size-multiplier":
    out.sizeMultiplier = clampNumber(value, 2, 16, DEFAULTS.sizeMultiplier); break
  case "opacity":
    out.opacity = clampNumber(value, 0.05, 1, DEFAULTS.opacity); break
  case "shape":
    var s = String(value)
    if (SHAPES.indexOf(s) !== -1) out.shape = s
    break
  case "border":
    out.border = (value === true || String(value) === "true")
    break
  }
  return out
}

function parse(text) {
  var out = defaults()
  var section = ""
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].replace(/^\s+|\s+$/g, "")
    if (!line || line.charAt(0) === "#") continue
    var sectionMatch = line.match(/^\[([A-Za-z0-9_.-]+)\]\s*(?:#.*)?$/)
    if (sectionMatch) { section = sectionMatch[1]; continue }
    if (section !== SECTION) continue
    var kv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(.+)$/)
    if (!kv) continue
    applyKey(out, kv[1], parseValue(kv[2]))
  }
  return out
}

function serialize(prefs) {
  var p = parse("") // start from typed defaults, then overlay
  applyKey(p, "duration", prefs.duration)
  applyKey(p, "fade", prefs.fade)
  applyKey(p, "reopen", prefs.reopen)
  applyKey(p, "size-multiplier", prefs.sizeMultiplier)
  applyKey(p, "opacity", prefs.opacity)
  applyKey(p, "shape", prefs.shape)
  applyKey(p, "border", prefs.border)
  return [
    "# Workspace OSD preferences (Omarchy). Managed by the plugin; safe to edit by hand.",
    "# shape: rectangle | rounded | circle",
    "[" + SECTION + "]",
    "duration = " + p.duration,
    "fade = " + p.fade,
    "reopen = " + p.reopen,
    "size-multiplier = " + p.sizeMultiplier,
    "opacity = " + p.opacity,
    "shape = \"" + p.shape + "\"",
    "border = " + (p.border ? "true" : "false"),
    ""
  ].join("\n")
}
