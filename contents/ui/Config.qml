/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    property alias cfg_showLegend: showSensorsLegendCheckbox.checked
    property alias cfg_showlabel: showSensorslabelCheckbox.checked
    property alias cfg_blockSize: blockSizeCombo.currentIndex

    Controls.Label {
        text: i18n("Options :")
        font.pointSize: Kirigami.Units.largeSpacing * 1.5
    }

    Controls.CheckBox {
        id: showSensorslabelCheckbox
        text: i18n("Show Value")
    }

    Controls.CheckBox {
        id: showSensorsLegendCheckbox
        text: i18n("Show Sensors Legend")
    }

    Controls.ComboBox {
        id: blockSizeCombo
        Kirigami.FormData.label: i18n("Block size:")
        model: [i18n("Small"), i18n("Medium"), i18n("Large")]
    }
}
