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

        Component.onCompleted: {
            if (history) { // Migrate to file-based history
                shared.showInfo(qsTr("Legacy history system detected. Attempting to migrate"))
                py.call('main.migrate_history', [history], function () {
                    var page = pageStack.find(function (p) { return !!p ? p.__sshazam_firstPage : false })
                    page.model.loadHistory()
                    shared.showInfo(qsTr("Migration complete. If you see no errors it means it was succsessful"))
                    history = ''
                })
            }
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

        function showError(text, summary) {
            notifier.appIcon = "image://theme/icon-lock-warning"
            if (text) notifier.body = text
            if (summary) notifier.summary = summary
            notifier.publish()
            console.log(text, summary)
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

        function applyBackup(backup, backupHistory, backupSettings, backupMiscSettings, callback) {
            if (backupHistory) appConfiguration.history = backup.history
            if (backupSettings) {
                appSettings.recognitionTime = backup.recognitionTime
                appSettings.rate = backup.rate
                appSettings.language = backup.language
            }
            if (backupMiscSettings) {
                appSettings.infoInNotifications = backup.infoInNotifications
                appSettings.proxyType = backup.proxyType
                appSettings.customProxy = backup.customProxy
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
        property bool historyLoading: false

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
        onReceived: console.log("got message from python: " + data)

        Component.onCompleted: {
            setHandler('recordingstate', function (state) { recognitionState = state })
            setHandler('historyloaded', function() { historyLoading = false })
            setHandler('history_unknown', function (name, text) { shared.showError(text, qsTranslate("Errors", "History was unable to load: %1").arg(name)) })
            setHandler('history_json', function (name, text) { shared.showError(text, qsTranslate("Errors", "History contained invalid JSON: %1").arg(name)) })
            setHandler('history_perms', function (name, text) { shared.showError(text, qsTranslate("Errors", "Insufficient permissions: %1").arg(name)) })
            setHandler('history_notlist', function (name, text) { shared.showError(qsTranslate("Errors", "History is not a list or tuple")) })


            addImportPath(Qt.resolvedUrl("../python"))
            importModule('main', function() {
                applySettings(true)
                initialized = true
            })
        }

        function setHistoryCallback(callback) {
            while (!initialized);
            setHandler('history', function (res, index) {
                if (res[0])
                    callback(index, res.slice(2))
            })
        }

        function applySettings(force) {
            if (initialized || force)
                call('main.set_settings', [
                         appSettings.recognitionTime,
                         appSettings.rate,
                         !!appSettings.language ? appSettings.language :  Qt.locale().uiLanguages[0],
                         shared.getProxy(),
                         StandardPaths.data,
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

        /*function loadHistoryRecord(record, callback) {
            call('main.load', [record], function (res) {
                if (res[0])
                    callback(res[2], res[3], res[4], res[5])
            })
        }*/

        function exportHistory(path, backupHistory, backupSettings, backupMiscSettings, callback) {
            var backup = {}
            if (backupHistory) backup.history = appConfiguration.history
            if (backupSettings) {
                backup.recognitionTime = appSettings.recognitionTime
                backup.rate = appSettings.rate
                backup.language = appSettings.language
            }
            if (backupMiscSettings) {
                backup.infoInNotifications = appSettings.infoInNotifications
                backup.proxyType = appSettings.proxyType
                backup.customProxy = appSettings.customProxy
            }
           call('main.export_data', [path, new Date().toLocaleString(Qt.locale(), Locale.ShortFormat), backup], function(res) {
                if (res[0] === 1) callback(res[0], res[1], res[2])
                else callback(res[0])
           })
        }

        function importHistory(path, callback) {
            call('main.import_data', [path], function(res) {
                if (res[0] === 1) callback(res[0], res[1], res[2], res[3])
                else if (res[0] === 0) callback(res[0], res[1])
                else callback(res[0])
           })
        }

        function loadHistory() {
            historyLoading = true
            call('main.load_history', [])
        }
    }
}
