import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaListView {
        anchors.fill: parent
        model: ListModel {
            id: history
            function loadHistory() {
                appConfiguration.getHistory().forEach(function (record) {
                    py.loadHistoryRecord(record, function(t,s) {
                        append({ title: t, subtitle: s })
                    })
                })
            }
            Component.onCompleted: loadHistory()
        }

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Show Page 2")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("SecondPage.qml"))
            }
        }

        header: Column {
            width: parent.width
            PageHeader {
                title: "SShazam"
            }

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

                    Behavior on height {
                        NumberAnimation { duration: 500 }
                    }

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

            /*ButtonLayout {
                Button {
                    text: "Recognize"
                    icon.source: "image://theme/icon-m-music"
                    onClicked: py.call('main.record', [], function (res) {
                        if (!res[0]) return
                        console.log(JSON.stringify(res))
                        py.title = res[1]
                        py.subtitle = res[2]
                    })
                }
            }*/

            SectionHeader {
                text: "Recognition Result"
                visible: py.trackFound
            }

            ListItem {
                contentHeight: Theme.itemSizeExtraLarge
                visible: py.trackFound

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

            SectionHeader  {
                text: "History"
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

        /*// Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("UI Template")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Hello Sailors")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
        }*/


    }
}
