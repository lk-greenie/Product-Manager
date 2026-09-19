#include <QtTest>

#include "appconfig.h"
#include "serverconnectionsettings.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QTemporaryDir>
#include <QTextStream>

class ServerConnectionSettingsTest : public QObject
{
    Q_OBJECT

private slots:
    void generatedEncryptedConfigIsImportedWithoutPlaintextCredentials();
    void rememberedLoginIsStoredEncryptedAndReloaded();
};

void ServerConnectionSettingsTest::generatedEncryptedConfigIsImportedWithoutPlaintextCredentials()
{
    QTemporaryDir temporaryDirectory;
    QVERIFY(temporaryDirectory.isValid());

    const QString configDirectory = temporaryDirectory.filePath(QStringLiteral("config"));
    QVERIFY(QDir().mkpath(configDirectory));
    const QString appConfigPath = configDirectory + QStringLiteral("/app.ini");
    QFile appConfig(appConfigPath);
    QVERIFY(appConfig.open(QIODevice::WriteOnly | QIODevice::Text));
    QTextStream configStream(&appConfig);
    configStream << "[userDatabase]\n"
                 << "driver=QMYSQL\n"
                 << "name=user_management\n\n"
                 << "[businessDatabase]\n"
                 << "driver=QMYSQL\n"
                 << "name=warehouse\n";
    appConfig.close();

    qputenv("QML_PRODUCT_MANAGER_CONFIG", appConfigPath.toUtf8());
    AppConfig::load();
    QVERIFY(AppConfig::isLoaded());

    ServerConnectionSettings settings(nullptr, nullptr);
    QVERIFY(settings.generateEncryptedConfig(QStringLiteral("192.168.10.8"), 3307,
                                              QStringLiteral("warehouse_user"),
                                              QStringLiteral("sensitive-password"),
                                              QStringLiteral("user_management"),
                                              QStringLiteral("warehouse")));

    const QString encryptedPath = settings.encryptedConfigPath();
    QVERIFY(QFileInfo::exists(encryptedPath));
    QCOMPARE(AppConfig::stringValue(QStringLiteral("userDatabase/host")),
             QStringLiteral("192.168.10.8"));
    QCOMPARE(AppConfig::stringValue(QStringLiteral("businessDatabase/username")),
             QStringLiteral("warehouse_user"));

    AppConfig::load();
    QVERIFY(!AppConfig::hasDatabaseServerConfig());
    QString importError;
    QVERIFY(ServerConnectionSettings::importDefaultEncryptedConfig(&importError));
    QCOMPARE(AppConfig::stringValue(QStringLiteral("userDatabase/host")),
             QStringLiteral("192.168.10.8"));

    QFile encryptedFile(encryptedPath);
    QVERIFY(encryptedFile.open(QIODevice::ReadOnly));
    const QByteArray encryptedContents = encryptedFile.readAll();
    QVERIFY(!encryptedContents.contains("192.168.10.8"));
    QVERIFY(!encryptedContents.contains("sensitive-password"));
}

void ServerConnectionSettingsTest::rememberedLoginIsStoredEncryptedAndReloaded()
{
    QTemporaryDir temporaryDirectory;
    QVERIFY(temporaryDirectory.isValid());

    const QString configDirectory = temporaryDirectory.filePath(QStringLiteral("config"));
    QVERIFY(QDir().mkpath(configDirectory));
    const QString appConfigPath = configDirectory + QStringLiteral("/app.ini");
    QFile appConfig(appConfigPath);
    QVERIFY(appConfig.open(QIODevice::WriteOnly | QIODevice::Text));
    appConfig.close();

    qputenv("QML_PRODUCT_MANAGER_CONFIG", appConfigPath.toUtf8());
    AppConfig::load();
    QVERIFY(AppConfig::isLoaded());

    ServerConnectionSettings settings(nullptr, nullptr);
    QVERIFY(settings.saveRememberedLogin(QStringLiteral("remembered-user"),
                                         QStringLiteral("remembered-password"), true));
    QCOMPARE(settings.rememberedUsername(), QStringLiteral("remembered-user"));
    QCOMPARE(settings.rememberedPassword(), QStringLiteral("remembered-password"));
    QVERIFY(settings.rememberLogin());

    const QString credentialsPath = configDirectory + QStringLiteral("/login_credentials.enc");
    QFile credentialsFile(credentialsPath);
    QVERIFY(credentialsFile.open(QIODevice::ReadOnly));
    const QByteArray encryptedContents = credentialsFile.readAll();
    QVERIFY(!encryptedContents.contains("remembered-user"));
    QVERIFY(!encryptedContents.contains("remembered-password"));

    ServerConnectionSettings reloadedSettings(nullptr, nullptr);
    QCOMPARE(reloadedSettings.rememberedUsername(), QStringLiteral("remembered-user"));
    QCOMPARE(reloadedSettings.rememberedPassword(), QStringLiteral("remembered-password"));
    QVERIFY(reloadedSettings.rememberLogin());
}

QTEST_MAIN(ServerConnectionSettingsTest)

#include "server_connection_settings_test.moc"
