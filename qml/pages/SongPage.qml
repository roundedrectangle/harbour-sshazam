import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Page {
    property string title
    property string subtitle
    property url image

    SilicaFlickable {
        anchors.fill: parent

        Image {
            source: image
            width: Screen.width
            height: width
            fillMode: Image.PreserveAspectCrop

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
                    x: Theme.paddingLarge
                    width: parent.width-2*x
                    font.pixelSize: Theme.fontSizeHuge

                    /*layer.enabled: true
                    layer.effect: DropShadow {
                        verticalOffset: 20
                        horizontalOffset: 20
                        color: Theme.secondaryColor
                        radius: 8
                        samples: 17
                        spread: 0
                    }*/
                }

                Label {
                    text: subtitle
                    color: Theme.secondaryHighlightColor
                    x: Theme.paddingLarge
                    width: parent.width-2*x
                }
            }
        }
    }
}
