#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QIcon>
#include <QMessageLogContext>
#include <QTextStream>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include "appconfig.h"
#include "enter.h"
#include "tabledisplay.h"
#include "deepseekclient.h"

namespace {
QtMessageHandler s_previousMessageHandler = nullptr;
QFile s_logFile;

void writeMessageToLog(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    const QString formatted = qFormatLogMessage(type, context, message);
    if (s_logFile.isOpen()) {
        QTextStream stream(&s_logFile);
        stream << formatted << Qt::endl;
        stream.flush();
    }

    if (s_previousMessageHandler)
        s_previousMessageHandler(type, context, message);
}

void installLogFileHandler()
{
    const QString logPath = AppConfig::stringValue(
        QStringLiteral("application/logFile"),
        QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("qmlProductManager.log")));
    s_logFile.setFileName(logPath);
    if (!s_logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        qWarning().noquote() << QStringLiteral("无法打开日志文件：%1").arg(QDir::toNativeSeparators(logPath));
        return;
    }

    s_previousMessageHandler = qInstallMessageHandler(writeMessageToLog);
    qInfo().noquote() << QStringLiteral("日志文件：%1").arg(QDir::toNativeSeparators(logPath));
}
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    AppConfig::load();

    QCoreApplication::setOrganizationName(AppConfig::stringValue(QStringLiteral("application/organizationName"),
                                                                 QStringLiteral("ECJTU")));
    QCoreApplication::setOrganizationDomain(AppConfig::stringValue(QStringLiteral("application/organizationDomain"),
                                                                   QStringLiteral("ecjtu.local")));
    QCoreApplication::setApplicationName(AppConfig::stringValue(QStringLiteral("application/name"),
                                                                QStringLiteral("qmlProductManager")));

    const QString graphicsApi = AppConfig::stringValue(QStringLiteral("application/graphicsApi"),
                                                       QStringLiteral("OpenGL"));
    if (graphicsApi.compare(QStringLiteral("OpenGL"), Qt::CaseInsensitive) == 0)
        QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    installLogFileHandler();
    qInfo().noquote() << QStringLiteral("配置文件：%1").arg(QDir::toNativeSeparators(AppConfig::filePath()));
    if (!AppConfig::isLoaded())
        qWarning().noquote() << AppConfig::errorMessage();

    const QString controlsStyle = AppConfig::stringValue(QStringLiteral("application/controlsStyle"),
                                                         QStringLiteral("Basic"));
    if (!controlsStyle.isEmpty())
        qputenv("QT_QUICK_CONTROLS_STYLE", controlsStyle.toUtf8());

    app.setWindowIcon(QIcon(AppConfig::stringValue(QStringLiteral("application/icon"),
                                                    QStringLiteral(":/images/favicon.ico"))));

    // 先构造两个后端对象
    Enter loginManager;
    TableDisplay display;
    DeepSeekClient aiManager;

    QQmlApplicationEngine engine;
    // 在 engine.load() 之前注册全部上下文属性，
    // 保证 QML 首次加载即可访问 loginManager 与 TableDisplay
    engine.rootContext()->setContextProperty("loginManager", &loginManager);
    engine.rootContext()->setContextProperty("TableDisplay", &display);
    engine.rootContext()->setContextProperty("aiManager", &aiManager);
    QObject::connect(&loginManager, &Enter::currentUserChanged, &aiManager, [&loginManager, &aiManager] {
        aiManager.setCurrentUser(loginManager.userId());
    });

    const QUrl url(AppConfig::stringValue(QStringLiteral("application/qmlEntry"),
                                          QStringLiteral("qrc:/qml/Login&Register/Enter.qml")));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
