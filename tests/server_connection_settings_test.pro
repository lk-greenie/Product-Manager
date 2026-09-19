QT += core sql testlib

CONFIG += c++17 console testcase
CONFIG -= app_bundle

SOURCES += \
    server_connection_settings_test.cpp \
    ../src/app/appconfig.cpp \
    ../src/app/serverconnectionsettings.cpp \
    ../src/backend/auth/enter.cpp \
    ../src/backend/inventory/tabledisplay_db_models.cpp \
    ../src/backend/inventory/tabledisplay_inventory.cpp \
    ../src/backend/inventory/tabledisplay_query.cpp \
    ../src/backend/inventory/tabledisplay_context.cpp

HEADERS += \
    ../src/app/appconfig.h \
    ../src/app/serverconnectionsettings.h \
    ../src/backend/auth/enter.h \
    ../src/backend/inventory/tabledisplay.h

INCLUDEPATH += \
    ../src/app \
    ../src/backend/auth \
    ../src/backend/inventory

win32:LIBS += -lcrypt32
