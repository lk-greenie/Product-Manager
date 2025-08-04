#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QApplication>
#include <QWidget>
#include <QWindow>
#include <QVBoxLayout>
#include "enter.h"
#include "tabledisplay.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    Enter loginManager;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("loginManager", &loginManager);

    const QUrl url(QStringLiteral("qrc:qml/Enter.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    TableDisplay display;

    engine.rootContext()->setContextProperty("TableDisplay", &display);

    return app.exec();
}
