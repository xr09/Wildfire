/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.faces as Faces
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls
import org.kde.plasma.core as PlasmaCore

Faces.SensorFace {
    id: root
    readonly property bool showLegend: controller.faceConfiguration.showLegend
    readonly property bool showlabel: controller.faceConfiguration.showlabel

    contentItem: ColumnLayout {

        Kirigami.Heading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.controller.title
            visible: root.controller.showTitle && text.length > 0
            level: 2
        }

        Loader {
            id: loader
            source: Qt.resolvedUrl("Wildfire.qml")
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 5 * Kirigami.Units.gridUnit
            Layout.preferredHeight: 8 * Kirigami.Units.gridUnit
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
        }

        ColumnLayout {
            visible: root.showLegend

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Repeater {
                model: root.controller.highPrioritySensorIds.concat(
                           root.controller.lowPrioritySensorIds)

                ChartsControls.LegendDelegate {
                    readonly property bool isTextOnly: index >= root.controller.highPrioritySensorIds.length

                    Layout.fillWidth: true
                    Layout.minimumHeight: isTextOnly ? 0 : implicitHeight

                    name: sensor.shortName
                    value: sensor.formattedValue
                    visible: !isTextOnly
                    color: root.colorSource.map[modelData]

                    Sensors.Sensor {
                        id: sensor
                        sensorId: modelData
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
