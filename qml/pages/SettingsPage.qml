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
                    text: qsTr("Export backup")
                    onClicked: pageStack.push(itemsDialog)
                }
                Button {
                    text: qsTr("Import backup")
                    onClicked: {
                        var dialog = pageStack.push("Sailfish.Pickers.FilePickerPage", { nameFilters: ['*.json'] })
                        dialog.selectedContentPropertiesChanged.connect(function () {
                            var page = pageStack.push(loadingPage)
                            py.importHistory(dialog.selectedContentProperties.filePath, page.importCallback)
                        })
                    }
                }
            }

            Item { width:1; height: Theme.paddingLarge }
        }
    }

    Component {
        id: itemsDialog
        Dialog {
            property string selectedPath
            property var importData: ({})
            property bool doExport: true
            Column {
                width: parent.width

                DialogHeader { title: doExport ? qsTr("Select items to backup") : qsTr("Select items to import") }
                Label {
                    text: qsTr("All items you select will be overwritten! If you select recognition history your current history will be overwritten!")
                    visible: !doExport
                    x: Theme.horizontalPageMargin
                    width: parent.width-x*2
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                IconTextSwitch {
                    id: historySwitch
                    visible: doExport || ('history' in importData)
                    text: qsTr("Recognition history")
                    icon.source: "image://theme/icon-m-history"
                }
                IconTextSwitch {
                    id: basicSwitch
                    visible: doExport || ('recognitionTime' in importData)
                    text: qsTr("Basic settings")
                    description: qsTr("Include Recognition section")
                    icon.source: "image://theme/icon-m-sounds"
                }
                IconTextSwitch {
                    id: otherSwitch
                    visible: doExport || ('infoInNotifications' in importData)
                    text: qsTr("Other settings")
                    description: qsTr("Include Debugging and Networking sections")
                    icon.source: "image://theme/icon-m-setting"
                }
            }

            canAccept: historySwitch.checked || basicSwitch.checked || otherSwitch.checked
            acceptDestination: doExport ? "Sailfish.Pickers.FolderPickerPage" : loadingPage
            onAcceptDestinationInstanceChanged: {
                if (!acceptDestinationInstance || !doExport) return
                acceptDestinationInstance.selectedPathChanged.connect(function() {
                    pageStack.completeAnimation()
                    var page = pageStack.replace(loadingPage)
                    py.exportHistory(acceptDestinationInstance.selectedPath, historySwitch.checked, basicSwitch.checked, otherSwitch.checked, page.callback)
                })
            }
            onAccepted: {
                shared.applyBackup(importData, historySwitch.checked, basicSwitch.checked, otherSwitch.checked)
                acceptDestinationInstance.finish()
            }
        }
    }

    Component {
        id: loadingPage
        Page {
            backNavigation: false
            property bool importing: false

            function showError(hintText, text) {
                error.hintText = hintText
                if (text) error.text = text
                busyLabel.running = false
            }

            function callbackBase(finalCallback, result, extraErrorName, extraErrorDescription) {
                switch (result) {
                case 0:
                    finalCallback()
                    break
                case 1:
                    showError(extraErrorDescription, qsTr("Unknown error: %1").arg(extraErrorName))
                    break
                case 2:
                    showError(qsTr("Insufficient permissions"))
                    break
                }
            }

            function finish() {
                pageStack.clear()
                pageStack.completeAnimation()
                pageStack.push(Qt.resolvedUrl('FirstPage.qml'))
            }

            function callback(result, extraErrorName, extraErrorDescription) {
                callbackBase(finish, result, extraErrorName, extraErrorDescription)
            }

            function importCallback(result, data, extraErrorName, extraErrorDescription) {
                callbackBase(function () {
                    pageStack.completeAnimation()
                    pageStack.push(itemsDialog, { importData: data, doExport: false })
                }, result, extraErrorName, extraErrorDescription)
            }

            SilicaFlickable {
                anchors.fill: parent
                BusyLabel {
                    id: busyLabel
                    running: true
                    text: importing ? qsTr("Import in progress") : qsTr("Export in progress")
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
