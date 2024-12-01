import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Page {
    property string title
    property string subtitle
    property var sections: []

    SilicaListView {
        id: root
        anchors.fill: parent
        model: sections

        delegate: Loader {
            width: parent.width
            sourceComponent: switch (type) {
                             case 'song': return songComponent
                             default: return null
                             }
            Component {
                id: songComponent
                PagedView {
                    id: songView
                    model: pages
                    width: Screen.width
                    height: width

                    delegate: Image {
                        width: PagedView.contentWidth
                        height: PagedView.contentHeight
                        source: image
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: infoColumn.width
                        height: infoColumn.height + infoColumn.anchors.bottomMargin + Theme.paddingLarge
                        opacity: 0.75
                        color: Theme.overlayBackgroundColor
                    }

                    Column {
                        id: infoColumn
                        width: parent.width
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: Theme.paddingLarge
                        }
                        Label {
                            text: title
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeHuge

                            x: Theme.paddingLarge
                            width: parent.width-2*x
                            wrapMode: Text.Wrap
                        }

                        Label {
                            text: subtitle
                            color: Theme.secondaryHighlightColor

                            x: Theme.paddingLarge
                            width: parent.width-2*x
                            wrapMode: Text.Wrap
                        }
                        Label {
                            text: songView.model.get(songView.currentIndex).caption
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor

                            x: Theme.paddingLarge
                            width: parent.width-2*x
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
