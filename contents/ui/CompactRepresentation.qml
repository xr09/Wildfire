/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.faces as Faces

Faces.SensorFace {
    id: root
    readonly property bool showlabel: controller.faceConfiguration.showlabel

    contentItem: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 3

        Loader {
            id: loader
            source: Qt.resolvedUrl("Wildfire.qml")
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: Math.max(root.width, Layout.minimumHeight)
        }
    }
}
