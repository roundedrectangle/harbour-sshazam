import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        anchors {
            fill: parent
            bottomMargin: Theme.paddingLarge
        }
        spacing: Theme.paddingLarge
        model: ListModel {
            function loadHistory() {
                py.trackFound = false
                clear()
                appConfiguration.getHistory().forEach(function (record, i) {
                    py.loadHistoryRecord(record, function(t,s,i) {
                        append({ arrIndex: i, raw: record, title: t, subtitle: s, image: i })
                    })
                })
            }
            Component.onCompleted: loadHistory()
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Reload history")
                onClicked: listView.model.loadHistory()
            }
        }

        header: Column {
            width: parent.width
            PageHeader { title: "SShazam" }

            Item {
                height: Screen.width-Theme.horizontalPageMargin*2
                width: height
                anchors.horizontalCenter: parent.horizontalCenter

                IconButton {
                    icon.source: "image://theme/icon-l-music"
                    anchors.centerIn: parent
                    icon.fillMode: Image.Stretch
                    icon.sourceSize.height: height-Theme.paddingLarge*2
                    icon.sourceSize.width: height-Theme.paddingLarge*2
                    height: parent.height - Theme.itemSizeLarge
                    width: height

                    Behavior on height { NumberAnimation { duration: 500 } }

                    Timer {
                        id: animationTimer
                        property bool animating: false
                        repeat: true
                        interval: 500
                        onTriggered: {
                            if (animating) parent.height = parent.parent.height
                            else parent.height = parent.parent.height - Theme.itemSizeLarge
                            animating = !animating
                        }
                    }

                    onClicked: {
                        if (animationTimer.running) return
                        animationTimer.start()
                        if (py.trackFound) listView.model.loadHistory()
                        py.recognize(function() {
                            animationTimer.stop()
                            height = parent.height - Theme.itemSizeLarge
                        })
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.highlightBackgroundColor
                        opacity: 0.5
                        z: -1
                        radius: width*0.5
                    }
                }
            }

            SectionHeader {
                text: qsTr("Recognition Result")
                visible: py.trackFound
                opacity: visible ? 1 : 0
                height: visible ? implicitHeight : 0
                Behavior on opacity { FadeAnimation {} }
                Behavior on height { NumberAnimation { duration: 200 } }
            }

            ListItem {
                contentHeight: Theme.itemSizeExtraLarge
                visible: py.trackFound
                opacity: visible ? 1 : 0
                height: visible ? implicitHeight : 0
                Behavior on opacity { FadeAnimation {} }
                Behavior on height { NumberAnimation { duration: 200 } }

                Column {
                    width: parent.width - Theme.horizontalPageMargin*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        text: py.title
                    }
                    Label {
                        text: py.subtitle
                        color: Theme.secondaryColor
                    }
                }

                onClicked: pageStack.push(Qt.resolvedUrl('SongPage.qml'), { title: py.title, subtitle: py.subtitle, image: py.image })
            }

            SectionHeader {
                text: qsTr("History")
                opacity: listView.model.count > 0 ? 1 : 0
            }
        }

        delegate: ListItem {
            Column {
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    text: title
                }
                Label {
                    text: subtitle
                    color: Theme.secondaryColor
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl('SongPage.qml'), { title: title, subtitle: subtitle, image: image })

            menu: Component { ContextMenu {
                    MenuItem {
                        text: qsTr("Remove")
                        onClicked: {
                            var history = appConfiguration.getHistory()
                            if (history.length === listView.model.length) {
                                listView.model.loadHistory()
                                shared.showError(qsTr("Could not remove record. Please try again. History was outdated"))
                                return
                            }
                            history.splice(arrIndex, 1)
                            appConfiguration.setHistory(history)
                            listView.model.loadHistory()
                        }
                    }
                } }
        }
    }
}
