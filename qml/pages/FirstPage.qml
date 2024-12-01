import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: ListModel {
            function loadHistory() {
                appConfiguration.getHistory().forEach(function (record) {
                    py.loadHistoryRecord(record, function(t,s) {
                        append({ raw: record, title: t, subtitle: s })
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
            }

            SectionHeader {
                text: qsTr("History")
                visible: listView.model.count > 0
            }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeExtraLarge

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
        }
    }
}
