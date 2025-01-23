# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-sshazam

CONFIG += sailfishapp

SOURCES += src/harbour-sshazam.cpp

DISTFILES += qml/harbour-sshazam.qml \
    qml/cover/CoverPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    qml/pages/SettingsPage.qml \
    rpm/harbour-sshazam.changes.in \
    rpm/harbour-sshazam.changes.run.in \
    rpm/harbour-sshazam.spec \
    translations/*.ts \
    harbour-sshazam.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-sshazam-ru.ts \
    translations/harbour-sshazam-ab.ts \
    translations/harbour-sshazam-be.ts \
    translations/harbour-sshazam-cs.ts \
    translations/harbour-sshazam-de.ts \
    translations/harbour-sshazam-el.ts \
    translations/harbour-sshazam-et.ts \
    translations/harbour-sshazam-fi.ts \
    translations/harbour-sshazam-fr.ts \
    translations/harbour-sshazam-hu.ts \
    translations/harbour-sshazam-id.ts \
    translations/harbour-sshazam-es.ts \
    translations/harbour-sshazam-it.ts \
    translations/harbour-sshazam-lt.ts \
    translations/harbour-sshazam-nb_NO.ts \
    translations/harbour-sshazam-nn.ts \
    translations/harbour-sshazam-pl.ts \
    translations/harbour-sshazam-pt.ts \
    translations/harbour-sshazam-pt_BR.ts \
    translations/harbour-sshazam-ro.ts \
    translations/harbour-sshazam-sk.ts \
    translations/harbour-sshazam-sr.ts \
    translations/harbour-sshazam-sv.ts \
    translations/harbour-sshazam-ta.ts \
    translations/harbour-sshazam-tr.ts \
    translations/harbour-sshazam-uk.ts \
    translations/harbour-sshazam-zh_CN.ts \
    translations/harbour-sshazam-nl.ts \
    translations/harbour-sshazam-nl_BE.ts

images.files = images
images.path = /usr/share/$${TARGET}

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += python images

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
