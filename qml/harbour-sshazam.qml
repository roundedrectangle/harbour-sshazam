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
        appName: "SShazam"
    }

    ConfigurationGroup {
        path: '/apps/harbour-sshazam'
        id: appConfiguration

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
            if (value('history')) { // Migrate to file-based history
                shared.showInfo(qsTr("Legacy history system detected. Attempting to migrate"))
                py.setHandler('import_complete', function() {
                    py.reloadHistoryModel()
                    shared.showInfo(qsTr("Migration complete. If you see no errors it means it was succsessful"))
                    setValue('history', undefined)
                })
                py.call('main.import_history', [value('history')])
            }
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

        function showInfo(text, summary) {
            notifier.appIcon = "image://theme/icon-lock-information"
            if (text) notifier.body = text
            if (summary) notifier.summary = summary
            notifier.publish()
            console.log(text, summary)
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

        function applyBackup(backup, callback, backupHistory, backupSettings, backupMiscSettings) {
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
            if (backupHistory) py.call('main.import_history', [backup.history], callback)
            else callback()
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
        property var reloadHistoryModel: function() { shared.showError(qsTranslate("Errors", "Couldn't reload history: app is not initialized!")) }

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
        onReceived: console.log("got message from python: " + data)

        Component.onCompleted: {
            setHandler('recordingstate', function (state) { recognitionState = state })
            setHandler('historyloaded', function() { historyLoading = false })
            setHandler('history_unknown', function (name, text) { shared.showError(text, qsTranslate("Errors", "History was unable to load: %1").arg(name)) })
            setHandler('history_json', function (name, text) { shared.showError(text, qsTranslate("Errors", "History contained invalid JSON: %1").arg(name)) })
            setHandler('history_perms', function (name, text) { shared.showError(text, qsTranslate("Errors", "Insufficient permissions: %1").arg(name)) })
            setHandler('history_notlist', function (name, text) { shared.showError(qsTranslate("Errors", "History is not a list or tuple")) })
            setHandler('history_outdated', function (latest, outdated) {
                reloadHistoryModel()
                shared.showError(qsTranslate("Errors", "History was outdated. Latest length: %1, previously loaded length: %2").arg(latest).arg(outdated), qsTranslate("Errors", "Could not remove record. Please try again"))
            })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('main', function() {
                applySettings(true)
                initialized = true
            })
        }

        function setCallbacks(history, reload) {
            while (!initialized);
            reloadHistoryModel = reload
            setHandler('history', function (res, index) {
                if (res[0])
                    history(index, res.slice(2))
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
                } else {
                    trackFound = false
                    title = ''
                    subtitle = ''
                }
                recognitionState = 0
                finalCallback()
            })
        }

        function exportData(path, backupHistory, backupSettings, backupMiscSettings, callback) {
           var backup = {}
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
           call('main.export_data', [path, new Date().toLocaleString(Qt.locale(), Locale.ShortFormat), backup, backupHistory], function(res) {
                if (res[0] === 1) callback(res[0], res[1], res[2])
                else callback(res[0])
           })
        }

        function importData(path, callback) {
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

        function rebuildHistory() { call('main.rebuild_history', [], reloadHistoryModel) }
    }
}
