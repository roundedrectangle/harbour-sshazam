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
                Column {
                    width: parent.width
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

                        SectionHeader {
                            anchors.top: parent.top
                            text: tab
                            Rectangle {
                                z: -1
                                color: Theme.overlayBackgroundColor
                                opacity: 0.75
                                width: parent.parent.width
                                height: parent.height + Theme.paddingSmall
                                x: -parent.x
                            }
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

                    ColumnView {
                        width: parent.width
                        model: meta
                        itemHeight: Theme.itemSizeSmall
                        delegate: Label {
                            text: ('<font color="'+Theme.secondaryColor+'">%1:</font> <font color="'+Theme.primaryColor+'">%2</font>').arg(model.title).arg(model.text)
                            palette.primaryColor: Theme.highlightColor
                            verticalAlignment: Qt.AlignVCenter
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2*x
                            height: Theme.itemSizeSmall
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
