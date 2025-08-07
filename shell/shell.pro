QT += quick core x11extras

CONFIG += link_pkgconfig
PKGCONFIG += gtk+-3.0

# Define the path to the Flutter library
FLUTTER_LIB_PATH = ../flutter_app/build/linux/x64/release/bundle/lib
LIBS += -L${FLUTTER_LIB_PATH} -lflutter_linux_gtk

# Define the path to the Flutter headers
FLUTTER_INCLUDE_PATH = ../flutter_app/linux/flutter/ephemeral
INCLUDEPATH += ${FLUTTER_INCLUDE_PATH}

SOURCES += main.cpp \
           backend.cpp \
           flutter_embedder.cpp

HEADERS += backend.h \
           flutter_embedder.h

RESOURCES += qml.qrc \
             theme.qrc
