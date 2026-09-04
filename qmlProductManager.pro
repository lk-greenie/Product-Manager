QT += quick sql widgets network charts

CONFIG += c++17

SOURCES += \
    src/app/main.cpp \
    src/app/appconfig.cpp \
    src/app/serverconnectionsettings.cpp \
    src/backend/auth/enter.cpp \
    src/backend/ai/deepseekclient.cpp \
    src/backend/inventory/tabledisplay_db_models.cpp \
    src/backend/inventory/tabledisplay_inventory.cpp \
    src/backend/inventory/tabledisplay_query.cpp \
    src/backend/inventory/tabledisplay_context.cpp

HEADERS += \
    src/app/appconfig.h \
    src/app/serverconnectionsettings.h \
    src/backend/auth/enter.h \
    src/backend/ai/deepseekclient.h \
    src/backend/inventory/tabledisplay.h

INCLUDEPATH += \
    src/app \
    src/backend/auth \
    src/backend/ai \
    src/backend/inventory

RESOURCES += qml.qrc

# 将运行时配置复制到可执行文件所在目录，使程序无论从 Qt Creator 还是直接启动
# 都能找到 config/app.ini。Qt Creator 影子构建会把可执行文件放在 $(DESTDIR)
# （例如 build/Desktop_Qt_6_8_3_MinGW_64_bit-Debug/debug），配置需与其相邻。
# 使用相对路径避免项目目录含中文时由 MinGW 命令行编码导致 xcopy 找不到源目录。
# 该项目的 shadow build 目录位于 build/<kit>/，因此从 Makefile.Debug 到项目根目录为 ../../。
win32 {
    QMAKE_POST_LINK += $$QMAKE_COPY_DIR \"..\\..\\config\" \"$(dir $(DESTDIR_TARGET))config\"
}

QML_IMPORT_PATH =
QML_DESIGNER_IMPORT_PATH =

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
