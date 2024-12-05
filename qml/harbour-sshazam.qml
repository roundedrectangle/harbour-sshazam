import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.0
import Nemo.Notifications 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Notification { // Notifies about app status
        id: notifier
        replacesId: 0
        onReplacesIdChanged: if (replacesId !== 0) replacesId = 0
        isTransient: !appSettings.infoInNotifications
    }

    ConfigurationGroup {
        path: '/apps/harbour-sshazam'
        id: appConfiguration

        property string history: '[]'

        ConfigurationGroup {
            id: appSettings
            path: 'settings'

            property int recognitionTime: 10
            property int rate: 41000
            property string language: ""
            property bool infoInNotifications: true
            property string proxyType: "g"
            property string customProxy: ""

            onValueChanged: py.applySettings()
        }

        function getHistory() { return JSON.parse(history) }

        function setHistory(newValue) {
            history = JSON.stringify(newValue)
        }

        function addToHistory(value) {
            var parsed = getHistory()
            parsed.splice(0, 0, value)
            setHistory(parsed)
        }
    }

    DBusInterface {
        id: globalProxy
        bus: DBus.SystemBus
        service: 'net.connman'
        path: '/'
        iface: 'org.sailfishos.connman.GlobalProxy'

        signalsEnabled: true
        function propertyChanged(name, value) { updateProxy() }

        property string url
        Component.onCompleted: updateProxy()

        function updateProxy() {
            // Sets the `url` to the global proxy URL, if enabled. Only manual proxy is supported, only the first address is used and excludes are not supported: FIXME
            // When passing only one parameter, you can pass it without putting it into an array (aka [] brackets)
            typedCall('GetProperty', {type: 's', value: 'Active'}, function (active){
                if (active) typedCall('GetProperty', {type: 's', value: 'Configuration'}, function(conf) {
                    if (conf['Method'] === 'manual') url = conf['Servers'][0]
                    else url=''
                }, function(e){url=''}); else url=''
            }, function(e){url=''})
        }
    }

    Connections {
        target: globalProxy
        onUrlChanged: py.applySettings()
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

        function arrayToListModel(_parent, arr) {
            if (!arr.forEach) return arr
            var listModel = Qt.createQmlObject('import QtQuick 2.0;ListModel{}', _parent)
            arr.forEach(function(el, i) { listModel.append(el) })
            return listModel
        }

        function getProxy() {
            switch (appSettings.proxyType) {
            case "g": return globalProxy.url
            case "n": return
            case "c": return appSettings.customProxy
            }
        }
    }

    Python {
        id: py

        property bool initialized: false

        property bool trackFound: false
        property string title
        property string subtitle
        property var sections: []
        property int recognitionState: 0

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
        onReceived: console.log("got message from python: " + data)

        Component.onCompleted: {
            setHandler('recordingstate', function (state) { recognitionState = state })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('main', function() {
                applySettings(true)
                initialized = true
            })
        }

        function applySettings(force) {
            if (initialized || force)
                call('main.set_settings', [
                         appSettings.recognitionTime,
                         appSettings.rate,
                         !!appSettings.language ? appSettings.language :  Qt.locale().uiLanguages[0],
                         shared.getProxy(),
                     ])
        }

        function recognize(finalCallback) {
            finalCallback = !!finalCallback ? finalCallback : function() {}
            call('main.record', [], function (res) {
                if (res[0]) {
                    trackFound = true
                    title = res[2]
                    subtitle = res[3]
                    sections = res[4]
                    try { appConfiguration.addToHistory(res[1]) }
                    catch (err) {
                        console.log("Error adding to history "+err)
                        //console.log("Proceeding with reset")
                        //appConfiguration.history = '[]'
                    }
                } else {
                    trackFound = false
                    title = ''
                    subtitle = ''
                }
                recognitionState = 0
                finalCallback()
            })
        }

        function loadHistoryRecord(record, callback) {
            call('main.load', [record], function (res) {
                if (res[0])
                    callback(res[2], res[3], res[4], res[5] < 0 ? undefined : new Date(res[5]))
            })
        }
    }
}
