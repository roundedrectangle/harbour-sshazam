import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width
            PageHeader { title: qsTr("Settings") }

            SectionHeader { text: qsTr("Recognition") }
            TextField {
                id: timeField
                label: qsTr("Recognition time")
                inputMethodHints: Qt.ImhDigitsOnly // ImhDigitsOnly and ImhFormattedNumbersOnly seem to have no difference
                validator: RegExpValidator { regExp: /^\d+$/ }
                text: appSettings.recognitionTime
                onTextChanged: if (validator.regExp.test(text)) appSettings.recognitionTime = Number(text)

                rightItem: IconButton {
                    onClicked: timeField.text = "10"

                    width: icon.width
                    height: icon.height
                    icon.source: "image://theme/icon-splus-remove"
                    opacity: timeField.text == "10" ? 0 : 1
                    Behavior on opacity { FadeAnimator{} }
                }
            }

            TextField {
                id: rateField
                label: qsTr("Sample rate")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegExpValidator { regExp: /^\d+$/ }
                text: appSettings.rate
                onTextChanged: if (validator.regExp.test(text)) appSettings.rate = Number(text)

                rightItem: IconButton {
                    onClicked: rateField.text = "41000"

                    width: icon.width
                    height: icon.height
                    icon.source: "image://theme/icon-splus-remove"
                    opacity: rateField.text == "41000" ? 0 : 1
                    Behavior on opacity { FadeAnimator{} }
                }
            }

            SectionHeader { text: qsTr("Debugging") }
            TextSwitch {
                text: qsTr("Show info messages in notifications")
                checked: appSettings.infoInNotifications
                onCheckedChanged: appSettings.infoInNotifications = checked
            }

            SectionHeader { text: qsTr("Networking") }
            Label {
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Login page always uses the global proxy regardless of these settings. Attachments, avatars and other static elements may not use proxy at all. Restart the app to apply")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                bottomPadding: Theme.paddingMedium
            }
            ComboBox {
                id: proxyTypeBox
                property var values: ["g", "n", "c"]
                label: qsTr("Proxy")
                currentIndex: values.indexOf(appSettings.proxyType) == -1 ? 0 : values.indexOf(appSettings.proxyType)
                menu: ContextMenu {
                    MenuItem { text: qsTr("global proxy") }
                    MenuItem { text: qsTr("disable") }
                    MenuItem { text: qsTr("custom") }
                }

               onCurrentItemChanged: appSettings.proxyType = values[currentIndex]
            }
            TextField {
                enabled: proxyTypeBox.values[proxyTypeBox.currentIndex] == "c"
                label: qsTr("HTTP proxy address")
                description: qsTr("Specify port by semicolon, if required")
                text: appSettings.customProxy
                onTextChanged: appSettings.customProxy = text
            }

            SectionHeader { text: qsTr("Storage") }
            ButtonLayout {
                Button {
                    text: qsTr("Clear history")
                    onClicked: appConfiguration.history = '[]'
                }

                Button {
                    text: qsTr("Reset settings")
                    onClicked: appSettings.clear()
                }
            }
        }
    }
}
