import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
    id: root
    moduleName: "tantuyu.logitech-g-mouse"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    property var mouse: null

    Translations {
        id: strings
        directory: Qt.resolvedUrl("i18n")
    }

    // Active tab: "sensor" or "buttons"
    property string currentTab: "sensor"

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color urgent: bar ? bar.urgent : Color.urgent
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    readonly property bool mouseConnected: mouse ? mouse.connected : false
    readonly property string deviceName: mouse ? mouse.deviceName : "Logitech G Mouse"
    readonly property int batteryPercentage: mouse ? mouse.batteryPercentage : Model.LEVEL_UNKNOWN
    readonly property string batteryStatus: mouse ? mouse.batteryStatus : "unknown"
    readonly property int dpiX: mouse ? mouse.dpiX : 0
    readonly property int dpiY: mouse ? mouse.dpiY : 0
    readonly property int dpiMin: mouse ? mouse.dpiMin : 100
    readonly property int dpiMax: mouse ? mouse.dpiMax : 32000
    readonly property var dpiPresets: mouse ? mouse.dpiPresets : [800, 1200, 1600, 2400, 3200]
    readonly property int reportRate: mouse ? mouse.reportRate : 1000
    readonly property string onboardProfileMode: mouse ? mouse.onboardProfileMode : "unknown"
    readonly property string lod: mouse ? mouse.lod : "unknown"
    readonly property bool hasHits: mouse ? mouse.hasHits : false
    readonly property var hitsLeft: mouse ? mouse.hitsLeft : Model.defaultButton()
    readonly property var hitsRight: mouse ? mouse.hitsRight : Model.defaultButton()

    function open() {
        root.controller.show()
        if (mouse) mouse.refresh()
    }

    function close() {
        root.controller.hide()
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function") {
            return root.bar.switchPanelFrom(root.hostWidget || root, direction)
        }
        return false
    }

    onOpenedChanged: if (opened) {
        if (panelFlick) panelFlick.contentY = 0
        if (mouse) mouse.refresh()
        Qt.callLater(function () { keyCatcher.forceActiveFocus() })
    }

    // Popup keyboard panel
    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(380))
        contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(720))

        // Third-party bar APIs expose only this plugin's click targets.
        // Let real bar buttons receive clicks instead of forwarding through the overlay.
        // The bar window is full-screen; exclude only its painted strip.
        mask: Region {
            x: panel.barPos === "left" ? panel.barThickness : 0
            y: panel.barPos === "top" ? panel.barThickness : 0
            width: panel.screenW - (panel.barPos === "left" || panel.barPos === "right" ? panel.barThickness : 0)
            height: panel.screenH - (panel.barPos === "top" || panel.barPos === "bottom" ? panel.barThickness : 0)
        }

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function (direction) {
                root.switchPanel(direction);
            }

            Flickable {
                id: panelFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: content
                    width: panelFlick.width - (panelFlick.interactive ? Style.space(8) : 0)
                    spacing: Style.space(12)

                    // ── Dynamic Device Header ──
                    Row {
                        width: parent.width
                        spacing: Style.space(8)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍽"
                            color: root.foreground
                            font.family: "monospace"
                            font.pixelSize: Style.font.heading
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.deviceName.toUpperCase()
                            textFormat: Text.PlainText
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.subtitle
                            font.bold: true
                        }
                    }

                    // ── Battery & Telemetry Banner ──
                    Rectangle {
                        width: parent.width
                        height: Math.max(Style.space(50), telemetryRow.implicitHeight + Style.space(16))
                        radius: 8
                        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.mouseConnected ? 0.08 : 0.04)
                        border.width: 1
                        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

                        Row {
                            id: telemetryRow
                            width: parent.width - Style.space(24)
                            anchors.centerIn: parent
                            spacing: Style.space(14)

                            Text {
                                id: telemetryIcon
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.mouseConnected ? Model.batteryIcon(root.batteryPercentage, root.batteryStatus) : "󰍽"
                                color: root.foreground
                                opacity: root.mouseConnected ? 1.0 : 0.5
                                font.family: "monospace"
                                font.pixelSize: Style.font.display
                            }

                            Column {
                                width: telemetryRow.width - telemetryIcon.width - telemetryRow.spacing
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Style.space(2)

                                Text {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.PlainText
                                    text: root.mouseConnected ? strings.t("summary.battery").arg(Model.batteryText(root.batteryPercentage, I18n.formatNumber)).arg(Model.batteryStatusLabel(root.batteryStatus, strings.t)) : strings.t("connection.disconnected")
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.body
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.PlainText
                                    text: root.mouseConnected ? strings.t("summary.telemetry").arg(Model.dpiText(root.dpiX, root.dpiY, I18n.formatNumber)).arg(Model.lodLabel(root.lod, strings.t)).arg(I18n.formatNumber(root.reportRate)) : strings.t("connection.check")
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    opacity: 0.6
                                }
                            }
                        }
                    }

                    // ── TABS: only displayed if mouse supports HITS analog switches ──
                    Row {
                        width: parent.width
                        spacing: Style.space(6)
                        visible: root.mouseConnected && root.hasHits

                        Repeater {
                            model: [
                                {
                                    id: "sensor",
                                    label: strings.t("tab.sensor")
                                },
                                {
                                    id: "buttons",
                                    label: strings.t("tab.buttons")
                                }
                            ]
                            delegate: Rectangle {
                                width: Math.floor((content.width - Style.space(6)) / 2)
                                height: Style.space(30)
                                radius: 4
                                color: root.currentTab === modelData.id ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                border.width: root.currentTab === modelData.id ? 1 : 0
                                border.color: root.foreground

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    textFormat: Text.PlainText
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    font.bold: root.currentTab === modelData.id
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = modelData.id
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // ── TAB 1: SENSOR (DPI & POLLING RATE)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        width: parent.width
                        spacing: Style.space(12)
                        visible: root.mouseConnected && (!root.hasHits || root.currentTab === "sensor")

                        // Section 1: Sensitivity
                        Column {
                            width: parent.width
                            spacing: Style.space(8)

                            Text {
                                textFormat: Text.PlainText
                                text: strings.t("sensor.sensitivity")
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: true
                                opacity: 0.6
                            }

                            // Dynamic Presets Buttons (filling 100% width)
                            Row {
                                width: parent.width
                                spacing: Style.space(6)
                                Repeater {
                                    model: root.dpiPresets
                                    delegate: Rectangle {
                                        width: Math.floor((parent.width - Style.space(6) * (root.dpiPresets.length - 1)) / root.dpiPresets.length)
                                        height: Style.space(28)
                                        radius: 4
                                        color: root.dpiX === modelData ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                        border.width: root.dpiX === modelData ? 1 : 0
                                        border.color: root.foreground

                                        Text {
                                            anchors.centerIn: parent
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(modelData)
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.bodySmall
                                            font.bold: root.dpiX === modelData
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dpiSlider.value = modelData;
                                                if (root.mouse)
                                                root.mouse.setDpi(modelData);
                                            }
                                        }
                                    }
                                }
                            }

                            // Continuous DPI Slider (Dynamically bounded from dpiMin to dpiMax)
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("sensor.customSensitivity")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        opacity: 0.8
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.dpi").arg(I18n.formatNumber(Math.round(dpiSlider.dragging ? dpiSlider.liveValue : (root.mouse ? root.mouse.dpiX : 800))))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: dpiSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: root.dpiMin
                                    maximum: root.dpiMax
                                    step: 50
                                    integer: true
                                    tickCount: 0
                                    value: root.dpiX || 800
                                    onMoved: function (val) {
                                        dpiSlider.value = Math.round(val / 50) * 50;
                                    }
                                    onReleased: function (val) {
                                        var target = Math.round(val / 50) * 50;
                                        dpiSlider.value = target;
                                        if (root.mouse)
                                        root.mouse.setDpi(target);
                                    }
                                }

                                // Dynamic Min, Mid, and Max range markers
                                Item {
                                    width: parent.width
                                    height: Style.space(14)

                                    Text {
                                        anchors.left: parent.left
                                        textFormat: Text.PlainText
                                        text: I18n.formatNumber(root.dpiMin)
                                        color: root.foreground
                                        opacity: 0.35
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        textFormat: Text.PlainText
                                        text: I18n.formatNumber(Math.round(root.dpiMax / 2))
                                        color: root.foreground
                                        opacity: 0.25
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        textFormat: Text.PlainText
                                        text: I18n.formatNumber(root.dpiMax)
                                        color: root.foreground
                                        opacity: 0.35
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.foreground
                            opacity: 0.1
                        }

                        // Section 2: Report Rate
                        Column {
                            width: parent.width
                            spacing: Style.space(8)

                            RowLayout {
                                width: parent.width
                                height: Math.max(Style.space(20), implicitHeight)
                                spacing: Style.space(8)

                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.PlainText
                                    text: strings.t("sensor.reportRate")
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    font.bold: true
                                    opacity: 0.6
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    text: strings.t("value.rate").arg(I18n.formatNumber(root.mouse ? root.mouse.reportRate : 1000))
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    font.bold: true
                                }
                            }

                            // Rate Buttons: [125, 250, 500, 1000, 2000, 4000, 8000] (7 items filling 100% width)
                            Row {
                                width: parent.width
                                spacing: Style.space(6)
                                Repeater {
                                    model: [125, 250, 500, 1000, 2000, 4000, 8000]
                                    delegate: Rectangle {
                                        width: Math.floor((parent.width - Style.space(6) * 6) / 7)
                                        height: Style.space(26)
                                        radius: 4
                                        color: (root.mouse && root.mouse.reportRate === modelData) ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                        border.width: (root.mouse && root.mouse.reportRate === modelData) ? 1 : 0
                                        border.color: root.foreground

                                        Text {
                                            anchors.centerIn: parent
                                            textFormat: Text.PlainText
                                            text: modelData >= 1000 ? strings.t("value.rateK").arg(I18n.formatNumber(modelData / 1000)) : I18n.formatNumber(modelData)
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.caption
                                            font.bold: root.mouse && root.mouse.reportRate === modelData
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (root.mouse)
                                            root.mouse.setReportRate(modelData)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.foreground
                            opacity: 0.1
                        }

                        Column {
                            width: parent.width
                            spacing: Style.space(8)

                            Text {
                                textFormat: Text.PlainText
                                text: strings.t("profile.title")
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: true
                                opacity: 0.6
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                textFormat: Text.PlainText
                                text: root.onboardProfileMode === "onboard"
                                    ? strings.t("profile.onboardDescription")
                                    : root.onboardProfileMode === "host"
                                        ? strings.t("profile.hostDescription")
                                        : strings.t("profile.unavailable")
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.caption
                                opacity: 0.7
                            }

                            Row {
                                width: parent.width
                                spacing: Style.space(6)

                                Repeater {
                                    model: [
                                        { mode: "host", label: strings.t("profile.host") },
                                        { mode: "onboard", label: strings.t("profile.onboard") }
                                    ]

                                    delegate: Rectangle {
                                        width: Math.floor((parent.width - Style.space(6)) / 2)
                                        height: Style.space(28)
                                        radius: 4
                                        color: root.onboardProfileMode === modelData.mode
                                            ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)
                                            : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                        border.width: root.onboardProfileMode === modelData.mode ? 1 : 0
                                        border.color: root.foreground

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            textFormat: Text.PlainText
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.caption
                                            font.bold: root.onboardProfileMode === modelData.mode
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: root.mouse && root.onboardProfileMode !== "unknown"
                                            onClicked: root.mouse.setOnboardProfileMode(modelData.mode)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // ── TAB 2: BUTTONS (ONLY AVAILABLE IF MOUSE SUPPORTS HITS)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        width: parent.width
                        spacing: Style.space(14)
                        visible: root.mouseConnected && root.hasHits && root.currentTab === "buttons"

                        // ──────────────────────────────────────────
                        // ── LEFT BUTTON
                        // ──────────────────────────────────────────
                        Column {
                            width: parent.width
                            spacing: Style.space(10)

                            Rectangle {
                                width: parent.width
                                height: Style.space(24)
                                radius: 4
                                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Style.space(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    textFormat: Text.PlainText
                                    text: strings.t("buttons.left")
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    opacity: 0.85
                                }
                            }

                            // 1. Actuation Point Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.actuation")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(leftActSlider.dragging ? leftActSlider.liveValue : (root.mouse ? root.mouse.hitsLeft.actuation : 1)))).arg(I18n.formatNumber(10))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: leftActSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 1
                                    maximum: 10
                                    step: 1
                                    integer: true
                                    tickCount: 10
                                    value: root.hitsLeft.actuation || 1
                                    onMoved: function (val) {
                                        leftActSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        leftActSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setActuation(0, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 10
                                        Text {
                                            required property int index
                                            readonly property int level: index + 1
                                            readonly property int cur: Math.round(leftActSlider.dragging ? leftActSlider.liveValue : leftActSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 9) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }

                            // 2. Rapid Trigger Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.rapidTrigger")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(leftRtSlider.dragging ? leftRtSlider.liveValue : (root.mouse ? root.mouse.hitsLeft.rapidTrigger : 1)))).arg(I18n.formatNumber(5))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: leftRtSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 1
                                    maximum: 5
                                    step: 1
                                    integer: true
                                    tickCount: 5
                                    value: root.hitsLeft.rapidTrigger || 1
                                    onMoved: function (val) {
                                        leftRtSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        leftRtSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setRapidTrigger(0, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 5
                                        Text {
                                            required property int index
                                            readonly property int level: index + 1
                                            readonly property int cur: Math.round(leftRtSlider.dragging ? leftRtSlider.liveValue : leftRtSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 4) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }

                            // 3. Click Haptics Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.haptics")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(leftHapSlider.dragging ? leftHapSlider.liveValue : (root.mouse ? root.mouse.hitsLeft.haptics : 0)))).arg(I18n.formatNumber(5))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: leftHapSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 0
                                    maximum: 5
                                    step: 1
                                    integer: true
                                    tickCount: 6
                                    value: (root.hitsLeft && root.hitsLeft.haptics !== undefined) ? root.hitsLeft.haptics : 0
                                    onMoved: function (val) {
                                        leftHapSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        leftHapSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setHaptics(0, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 6
                                        Text {
                                            required property int index
                                            readonly property int level: index
                                            readonly property int cur: Math.round(leftHapSlider.dragging ? leftHapSlider.liveValue : leftHapSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 5) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }
                        }

                        // Divider between buttons
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.foreground
                            opacity: 0.1
                        }

                        // ──────────────────────────────────────────
                        // ── RIGHT BUTTON
                        // ──────────────────────────────────────────
                        Column {
                            width: parent.width
                            spacing: Style.space(10)

                            Rectangle {
                                width: parent.width
                                height: Style.space(24)
                                radius: 4
                                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Style.space(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    textFormat: Text.PlainText
                                    text: strings.t("buttons.right")
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    opacity: 0.85
                                }
                            }

                            // 1. Actuation Point Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.actuation")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(rightActSlider.dragging ? rightActSlider.liveValue : (root.mouse ? root.mouse.hitsRight.actuation : 1)))).arg(I18n.formatNumber(10))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: rightActSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 1
                                    maximum: 10
                                    step: 1
                                    integer: true
                                    tickCount: 10
                                    value: root.hitsRight.actuation || 1
                                    onMoved: function (val) {
                                        rightActSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        rightActSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setActuation(1, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 10
                                        Text {
                                            required property int index
                                            readonly property int level: index + 1
                                            readonly property int cur: Math.round(rightActSlider.dragging ? rightActSlider.liveValue : rightActSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 9) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }

                            // 2. Rapid Trigger Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.rapidTrigger")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(rightRtSlider.dragging ? rightRtSlider.liveValue : (root.mouse ? root.mouse.hitsRight.rapidTrigger : 1)))).arg(I18n.formatNumber(5))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: rightRtSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 1
                                    maximum: 5
                                    step: 1
                                    integer: true
                                    tickCount: 5
                                    value: root.hitsRight.rapidTrigger || 1
                                    onMoved: function (val) {
                                        rightRtSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        rightRtSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setRapidTrigger(1, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 5
                                        Text {
                                            required property int index
                                            readonly property int level: index + 1
                                            readonly property int cur: Math.round(rightRtSlider.dragging ? rightRtSlider.liveValue : rightRtSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 4) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }

                            // 3. Click Haptics Slider
                            Column {
                                width: parent.width
                                spacing: 0

                                RowLayout {
                                    width: parent.width
                                    height: Math.max(Style.space(20), implicitHeight)
                                    spacing: Style.space(8)

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.PlainText
                                        text: strings.t("buttons.haptics")
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }

                                    Text {
                                        textFormat: Text.PlainText
                                        text: strings.t("value.level").arg(I18n.formatNumber(Math.round(rightHapSlider.dragging ? rightHapSlider.liveValue : (root.mouse ? root.mouse.hitsRight.haptics : 0)))).arg(I18n.formatNumber(5))
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: rightHapSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: 0
                                    maximum: 5
                                    step: 1
                                    integer: true
                                    tickCount: 6
                                    value: (root.hitsRight && root.hitsRight.haptics !== undefined) ? root.hitsRight.haptics : 0
                                    onMoved: function (val) {
                                        rightHapSlider.value = Math.round(val);
                                    }
                                    onReleased: function (val) {
                                        rightHapSlider.value = Math.round(val);
                                        if (root.mouse)
                                        root.mouse.setHaptics(1, Math.round(val));
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)
                                    Repeater {
                                        model: 6
                                        Text {
                                            required property int index
                                            readonly property int level: index
                                            readonly property int cur: Math.round(rightHapSlider.dragging ? rightHapSlider.liveValue : rightHapSlider.value)
                                            readonly property bool isCurrent: level === cur
                                            textFormat: Text.PlainText
                                            text: I18n.formatNumber(level)
                                            color: root.foreground
                                            opacity: isCurrent ? 1.0 : 0.35
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isCurrent
                                            x: Math.max(0, Math.min(parent.width - implicitWidth, parent.width * (index / 5) - implicitWidth / 2))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

