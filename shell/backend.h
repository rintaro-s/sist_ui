#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QQmlEngine>

class Backend : public QObject
{
    Q_OBJECT
public:
    explicit Backend(QQmlEngine *engine, QObject *parent = nullptr);

    Q_INVOKABLE void launchTerminal();
    Q_INVOKABLE void launchBrowser();
    Q_INVOKABLE void launchFileManager();
    Q_INVOKABLE QVariantList getApplications();
    Q_INVOKABLE void executeCommand(const QString &command);
    Q_INVOKABLE double getCpuUsage();
    Q_INVOKABLE double getMemoryUsage();

private:
    QQmlEngine *m_engine;
    // For CPU usage calculation
    long long m_lastTotalCpuTime = 0;
    long long m_lastIdleCpuTime = 0;
};

#endif // BACKEND_H
