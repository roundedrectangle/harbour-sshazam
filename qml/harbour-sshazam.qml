import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.0
import Nemo.Notifications 1.0
import Nemo.Configuration 1.0

ApplicationWindow {
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Notification { // Notifies about app status
        id: notifier
        replacesId: 0
        onReplacesIdChanged: if (replacesId !== 0) replacesId = 0
    }

    ConfigurationGroup {
        path: '/apps/harbour-sshazam'
        id: appConfiguration

        property string history: '[]'

        ConfigurationGroup {
            id: appSettings
            path: 'settings'
            // placeholder
        }

        function getHistory() {
            return JSON.parse(history)
        }

        function addToHistory(value) {
            var parsed = JSON.parse(history)
            parsed.splice(0, 0, value)
            history = JSON.stringify(parsed)
        }
    }

    QtObject {
        id: shared

        function showInfo(text) {
            notifier.appIcon = "image://theme/icon-lock-information"
            notifier.body = text
            notifier.publish()
        }

        function showError(text) {
            notifier.appIcon = "image://theme/icon-lock-warning"
            notifier.body = text
            notifier.publish()
            console.log(text)
        }
    }

    Python {
        id: py

        property bool trackFound: false
        property string title
        property string subtitle

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
        onReceived: console.log("got message from python: " + data)

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../python"))
            importModule('main', function() {
                // call('main.recognize', ['/home/defaultuser/Music/Lensko - Circles [NCS Release].mp3'], function (res) {console.log(res)})
                //call('main.record', [], function (res) {console.log(res)})
            })
        }

        function recognize(finalCallback) {
            finalCallback = !!finalCallback ? finalCallback : function() {}
            call('main.record', [], function (res) {
                if (res[0]) {
                    trackFound = true
                    title = res[2]
                    subtitle = res[3]
                    try { appConfiguration.addToHistory(res[1]) }
                    catch (err) {
                        console.log("Error adding to history "+err)
                        console.log("Proceeding with reset")
                        appConfiguration.history = '[]'
                    }
                } else {
                    trackFound = false
                    title = ''
                    subtitle = ''
                }
                finalCallback()
            })
        }

        function loadHistoryRecord(record, callback) {
            call('main.load', [record], function (res) {
                if (res[0]) {
                    callback(res[2], res[3])
                } else return
            })
        }
    }
}
