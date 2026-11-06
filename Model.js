// Model.js — Pure JS helper for parsing superstrike-daemon JSON output.

var LEVEL_UNKNOWN = -1

function defaultButton() {
  return { actuation: 0, rapidTrigger: 0, haptics: 0 }
}

function defaultStatus() {
  return {
    ok: true,
    connected: false,
    deviceName: "Logitech G Mouse",
    batteryPercentage: LEVEL_UNKNOWN,
    batteryLevel: "unknown",
    batteryStatus: "unknown",
    dpiX: 0,
    defaultDpiX: 0,
    dpiY: 0,
    defaultDpiY: 0,
    dpiMin: 100,
    dpiMax: 32000,
    dpiPresets: [800, 1200, 1600, 2400, 3200],
    reportRate: 1000,
    onboardProfileMode: "unknown",
    lod: "unknown",
    hasHits: false,
    hitsLeft: defaultButton(),
    hitsRight: defaultButton(),
    error: ""
  }
}

function externalText(value, fallback, maxLength) {
  if (value === undefined || value === null) return fallback
  return String(value)
    .replace(/[<>&\u0000-\u001f\u007f]/g, "")
    .slice(0, maxLength) || fallback
}

function parseStatus(raw) {
  var s = defaultStatus()
  if (!raw || raw === "") return s

  var data
  try { data = JSON.parse(raw) }
  catch (e) { s.ok = false; s.error = "Invalid daemon status"; return s }

  s.connected = !!data.connected
  s.deviceName = externalText(data.deviceName, s.deviceName, 128)
  if (data.battery) {
    s.batteryPercentage = typeof data.battery.percentage === "number" ? data.battery.percentage : LEVEL_UNKNOWN
    s.batteryLevel = externalText(data.battery.level, "unknown", 32)
    s.batteryStatus = externalText(data.battery.status, "unknown", 32)
  }

  if (data.dpi) {
    s.dpiX = data.dpi.dpiX || 0
    s.defaultDpiX = data.dpi.defaultDpiX || 0
    s.dpiY = data.dpi.dpiY || 0
    s.defaultDpiY = data.dpi.defaultDpiY || 0
    s.lod = externalText(data.dpi.lod, "unknown", 32)
  }

  if (typeof data.dpiMin === "number") s.dpiMin = data.dpiMin
  if (typeof data.dpiMax === "number") s.dpiMax = data.dpiMax
  if (Array.isArray(data.dpiPresets) && data.dpiPresets.length > 0) {
    s.dpiPresets = data.dpiPresets
  }

  if (data.reportRate) {
    s.reportRate = Number(data.reportRate) || 1000
  }

  if (data.onboardProfileMode) {
    s.onboardProfileMode = externalText(data.onboardProfileMode.mode, "unknown", 32)
  }

  s.hasHits = !!data.hasHits

  if (data.hits) {
    if (data.hits.left) {
      s.hitsLeft = {
        actuation: data.hits.left.actuation || 0,
        rapidTrigger: data.hits.left.rapidTrigger || 0,
        haptics: typeof data.hits.left.haptics === "number" ? data.hits.left.haptics : 0
      }
    }
    if (data.hits.right) {
      s.hitsRight = {
        actuation: data.hits.right.actuation || 0,
        rapidTrigger: data.hits.right.rapidTrigger || 0,
        haptics: typeof data.hits.right.haptics === "number" ? data.hits.right.haptics : 0
      }
    }
  }

  if (data.error) s.error = externalText(data.error, "", 512)
  s.ok = true
  return s
}

// Standard glyphs matching Omarchy power & input plugins
function mouseIcon() {
  return "󰍽"  // nf-md-mouse
}

function batteryIcon(percentage, status) {
  var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
  var defaultIcons  = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  if (percentage === LEVEL_UNKNOWN) return "󰍽"
  var idx = Math.max(0, Math.min(9, Math.floor(percentage / 10)))

  if (status === "charging" || status === "charging_slow") {
    return chargingIcons[idx]
  }
  if (status === "full") return "󰂅"
  return defaultIcons[idx]
}

function batteryText(percentage, fmt) {
  if (percentage === LEVEL_UNKNOWN) return "--"
  return fmt(percentage) + "%"
}

function dpiText(dpiX, dpiY, fmt) {
  if (dpiX <= 0) return "--"
  if (dpiY > 0 && dpiY !== dpiX) return fmt(dpiX) + "×" + fmt(dpiY)
  return fmt(dpiX)
}

function lodLabel(lod, tr) {
  if (lod === "low") return tr("lod.low", "Low")
  if (lod === "medium") return tr("lod.medium", "Medium")
  if (lod === "high") return tr("lod.high", "High")
  return "--"
}

function batteryStatusLabel(status, tr) {
  switch (status) {
    case "discharging": return tr("battery.discharging", "Discharging")
    case "charging": return tr("battery.charging", "Charging")
    case "charging_slow": return tr("battery.chargingSlow", "Charging slowly")
    case "full": return tr("battery.full", "Fully charged")
    case "error": return tr("battery.error", "Battery error")
    case "unknown":
    default: return tr("battery.unknown", "Unknown")
  }
}

function actuationLabel(level) {
  if (level <= 0) return "--"
  return "L" + String(level)
}

function rapidTriggerLabel(level) {
  if (level <= 0) return "--"
  return "L" + String(level)
}

function hapticsLabel(level) {
  if (level < 0) return "--"
  return "L" + String(level)
}

function barTooltip(mouse, tr, fmt) {
  var name = (mouse && mouse.deviceName) ? mouse.deviceName : "Logitech G Mouse"
  if (!mouse || !mouse.connected) return tr("tooltip.disconnected", "%1 (Disconnected)").replace("%1", name)
  var parts = [name]
  if (mouse.batteryPercentage !== LEVEL_UNKNOWN) {
    parts.push(tr("tooltip.battery", "%1 (%2)")
      .replace("%1", batteryText(mouse.batteryPercentage, fmt))
      .replace("%2", batteryStatusLabel(mouse.batteryStatus, tr)))
  }
  if (mouse.dpiX > 0) {
    parts.push(tr("value.dpi", "%1 DPI").replace("%1", dpiText(mouse.dpiX, mouse.dpiY, fmt)))
  }
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    LEVEL_UNKNOWN: LEVEL_UNKNOWN,
    defaultStatus: defaultStatus,
    parseStatus: parseStatus,
    mouseIcon: mouseIcon,
    batteryIcon: batteryIcon,
    batteryText: batteryText,
    batteryStatusLabel: batteryStatusLabel,
    dpiText: dpiText,
    barTooltip: barTooltip,
    actuationLabel: actuationLabel,
    rapidTriggerLabel: rapidTriggerLabel,
    hapticsLabel: hapticsLabel,
    lodLabel: lodLabel
  }
}
