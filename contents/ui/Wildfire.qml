/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
    SPDX-FileCopyrightText: 2026 xr09 <xr09@users.noreply.github.com>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Controls as Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.faces as Faces

Item {
    id: chart

    Layout.minimumWidth: Kirigami.Units.gridUnit * 4
    Layout.minimumHeight: Kirigami.Units.gridUnit * 2

    // Usage of the primary (high priority) sensor as a 0..1 ratio.
    readonly property real rate: sensor.sensorRate

    // Whole-number readout, e.g. "45%" instead of "45.5%".
    readonly property string integerReadout:
        Math.trunc(totalSensor.value || 0)
        + totalSensor.formattedValue.replace(/[\d.,\s+-]/g, "")

    // Cold (idle) -> hot (busy), sampled from palette.png. A bar's colour is
    // picked by its usage: low readings stay cold, high readings burn hot.
    readonly property var palette: ["#01121A", "#005F73", "#099396",
        "#93D2BD", "#E8D7A4", "#ED9B00", "#CA6702", "#BB3F02",
        "#B02013", "#9C2227"]

    function colorFor(u) {          // u is an intensity in 0..1
        var n = palette.length
        var idx = Math.round(u * (n - 1))
        if (idx < 1)
            idx = 1                 // never the near-black palette[0] for a lit cell
        else if (idx > n - 1)
            idx = n - 1
        return palette[idx]
    }

    // Below this raw rate the column stays dark/inactive (true idle costs nothing).
    readonly property real activityFloor: 0.05
    // <1 lifts low/mid load so everyday CPU reads as activity; the curve is concave.
    readonly property real activityGamma: 0.6

    // Remap a raw 0..1 rate into a perceptual intensity, with a dead-zone below
    // activityFloor. Drives BOTH bar height and color so they stay in sync.
    function intensity(u) {
        if (u <= activityFloor)
            return 0
        var t = (u - activityFloor) / (1 - activityFloor)   // renormalize 0.05..1 -> 0..1
        return Math.pow(t, activityGamma)
    }

    // Pixel-art block size, user-selectable via the "Block size" setting
    // (0 = Small, 1 = Medium, 2 = Large). Bigger blocks read chunkier but leave
    // fewer rows/columns; the scale stays tied to gridUnit for DPI/font. A 1px
    // gap turns the bars into a crisp grid.
    readonly property var blockScales: [0.33, 0.45, 0.60]
    readonly property real blockScale:
        blockScales[controller.faceConfiguration.blockSize] || blockScales[1]
    readonly property int cell: Math.max(3, Math.round(Kirigami.Units.gridUnit * blockScale))
    readonly property int gap: cell >= 5 ? 1 : 0

    // Faint "unlit" cell colour so the pixel matrix stays visible on any theme.
    readonly property color gridColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                               Kirigami.Theme.textColor.g,
                                               Kirigami.Theme.textColor.b, 0.08)

    // Rolling history of usage samples, newest last.
    property var history: []

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onGridColorChanged: requestPaint()
        onCellChanged: requestPaint()

        // These live on chart; mirror them so the handlers above resolve and a
        // config change (e.g. block size) repaints without waiting for a tick.
        property color gridColor: chart.gridColor
        property int cell: chart.cell

        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height
            ctx.clearRect(0, 0, w, h)

            var cs = chart.cell
            if (cs <= 0)
                return
            var cols = Math.floor(w / cs)
            var rows = Math.floor(h / cs)
            if (cols <= 0 || rows <= 0)
                return

            var g = chart.gap
            // Right-align the grid so the newest sample hugs the right edge.
            var offX = w - cols * cs
            var n = chart.history.length

            for (var c = 0; c < cols; c++) {
                // Map this column to a history entry (rightmost = newest).
                var hi = n - cols + c
                var hasData = hi >= 0
                var u = hasData ? chart.history[hi] : 0
                var iu = chart.intensity(u)
                var lit = (hasData && iu > 0) ? Math.max(1, Math.round(iu * rows)) : 0
                var litColor = chart.colorFor(iu)

                for (var r = 0; r < rows; r++) {
                    var x = offX + c * cs
                    var y = h - (r + 1) * cs
                    ctx.fillStyle = (r < lit) ? litColor : chart.gridColor
                    ctx.fillRect(x, y, cs - g, cs - g)
                }
            }
        }
    }

    // One sample per tick; push it, drop what scrolled off the left, repaint.
    // Paused when the widget is not visible so it costs nothing in the tray.
    Timer {
        interval: 1000
        running: chart.visible
        repeat: true
        onTriggered: {
            chart.history.push(chart.rate)
            var maxCols = Math.max(1, Math.ceil(canvas.width / chart.cell))
            while (chart.history.length > maxCols)
                chart.history.shift()
            canvas.requestPaint()
        }
    }

    // Small current-value readout, kept legible with a faint backing plate.
    Rectangle {
        visible: root.showlabel && valueLabel.text.length > 0
        anchors.centerIn: valueLabel
        width: valueLabel.width + Kirigami.Units.smallSpacing * 2
        height: valueLabel.height + Kirigami.Units.smallSpacing
        radius: height * 0.25
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Controls.Label {
        id: valueLabel
        visible: root.showlabel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Kirigami.Units.smallSpacing * 2
        color: "#ffffff"
        font.bold: true
        font.pixelSize: Math.max(8, Math.round(
                            Math.min(chart.width, chart.height) * 0.22))
        text: chart.integerReadout
    }

    FastBlur {
        z: -1
        visible: controller.faceConfiguration.glow
        anchors.fill: canvas
        source: canvas
        radius: Kirigami.Units.gridUnit / 2
    }

    Sensors.Sensor {
        id: totalSensor
        sensorId: root.controller.totalSensors[0]
    }

    Sensors.Sensor {
        id: sensor
        property real sensorRate: value / Math.max(value, maximum) || 0
        sensorId: root.controller.highPrioritySensorIds[0]
    }
}
