import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/Opal/About"
import "../modules/Opal/Attributions"

AboutPageBase {
    allowedOrientations: Orientation.All

    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    appName: "SShazam"
    appIcon: Qt.resolvedUrl("../../images/%1.png".arg(Qt.application.name))
    sourcesUrl: "https://github.com/roundedrectangle/harbour-sshazam"
    licenses: License { spdxId: "GPL-3.0-or-later" }
    description: qsTr("Shazam for SailfishOS")
    autoAddOpalAttributions: true
    authors: "roundedrectangle"

    attributions: [
        Attribution {
            name: "ShazamIO"
            entries: "2021 dotX12"
            licenses: License { spdxId: "MIT" }
            sources: "https://github.com/shazamio/ShazamIO"
        },
        Attribution {
            name: "pasimple"
            entries: "2022 Henrik Schnor"
            licenses: License { spdxId: "MIT" }
            sources: "https://github.com/henrikschnor/pasimple"
        }
    ]
    contributionSections: [
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup {
                    title: qsTr("Italian")
                    entries: ["247"]
                },
                ContributionGroup {
                    title: qsTr("Swedish")
                    entries: ["eson57"]
                },
                ContributionGroup {
                    title: qsTr("Spanish")
                    entries: ["carlosgonz0"]
                },
                ContributionGroup {
                    title: qsTr("Dutch")
                    entries: ["MPolleke"]
                },
                ContributionGroup {
                    title: qsTr("Belgium")
                    entries: ["MPolleke"]
                }
            ]
        }
    ]
}
