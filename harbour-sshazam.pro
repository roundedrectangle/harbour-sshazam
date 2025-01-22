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
TRANSLATIONS += harbour-sshazam-ru.ts \
    harbour-sshazam-ab.ts \
    harbour-sshazam-be.ts \
    harbour-sshazam-cs.ts \
    harbour-sshazam-de.ts \
    harbour-sshazam-el.ts \
    harbour-sshazam-et.ts \
    harbour-sshazam-fi.ts \
    harbour-sshazam-fr.ts \
    harbour-sshazam-hu.ts \
    harbour-sshazam-id.ts \
    harbour-sshazam-es.ts \
    harbour-sshazam-it.ts \
    harbour-sshazam-lt.ts \
    harbour-sshazam-nb_NO.ts \
    harbour-sshazam-nn.ts \
    harbour-sshazam-pl.ts \
    harbour-sshazam-pt.ts \
    harbour-sshazam-pt_BR.ts \
    harbour-sshazam-ro.ts \
    harbour-sshazam-sk.ts \
    harbour-sshazam-sr.ts \
    harbour-sshazam-sv.ts \
    harbour-sshazam-ta.ts \
    harbour-sshazam-tr.ts \
    harbour-sshazam-uk.ts \
    harbour-sshazam-zh_CN.ts \
    harbour-sshazam-nl.ts \
    harbour-sshazam-nl_BE.ts

images.files = images
images.path = /usr/share/$${TARGET}

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += python images

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
