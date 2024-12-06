import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

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
            TextField {
                label: qsTr("Shazam language")
                description: qsTr("Example: en-US. Leave empty to use system language")
                text: appSettings.language
                onTextChanged: appSettings.language = text
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
                text: qsTr("Album arts and other static elements may not use proxy at all. App restart might be required")
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
                Button {
                    text: qsTr("Export history")
                    onClicked: pageStack.push(exportItemsDialog)
                }
                Button {
                    text: qsTr("Import history")
                }
            }

            Item { width:1; height: Theme.paddingLarge }
        }
    }

    Component {
        id: exportItemsDialog
        Dialog {
            property string selectedPath
            Column {
                width: parent.width

                DialogHeader {
                    title: qsTr("Select items to backup")
                }
                IconTextSwitch {
                    id: historySwitch
                    text: qsTr("Recognition history")
                    icon.source: "image://theme/icon-m-history"
                }
                IconTextSwitch {
                    id: basicSwitch
                    text: qsTr("Basic settings")
                    description: qsTr("Include Recognition section")
                    icon.source: "image://theme/icon-m-sounds"
                }
                IconTextSwitch {
                    id: otherSwitch
                    text: qsTr("Other settings")
                    description: qsTr("Include Debugging and Networking sections")
                    icon.source: "image://theme/icon-m-setting"
                }
            }

            acceptDestination: "Sailfish.Pickers.FolderPickerPage"

            onAcceptDestinationInstanceChanged: {
                if (!acceptDestinationInstance) return
                acceptDestinationInstance.selectedPathChanged.connect(function() {
                    pageStack.completeAnimation()
                    var page = pageStack.replace(loadingPage)
                    py.exportHistory(selectedPath, historySwitch.checked, basicSwitch.checked, otherSwitch.checked, page.callback)
                })
            }
        }
    }

    Component {
        id: loadingPage
        Page {
            backNavigation: false

            function showError(hintText, text) {
                error.hintText = hintText
                if (text) error.text = text
                busyLabel.running = false
            }

            function callback(result, extraErrorName, extraErrorDescription) {
                switch (result) {
                case 0:
                    pageStack.clear()
                    pageStack.completeAnimation()
                    pageStack.push(Qt.resolvedUrl('FirstPage.qml'))
                    break
                case 1:
                    showError(extraErrorDescription, qsTr("Unknown error: %1").arg(extraErrorName))
                    break
                case 2:
                    showError(qsTr("Insufficient permissions"))
                    break
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                BusyLabel {
                    id: busyLabel
                    running: true
                    text: qsTr("Export in progress")
                }
                ViewPlaceholder {
                    id: error
                    enabled: !busyLabel.running
                    text: qsTr("An error occured")
                }
            }
        }
    }
}
