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
                label: qsTr("Rate")
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
        }
    }
}
