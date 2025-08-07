#include "backend.h"
#include <QProcess>
#include <QDir>
#include <QDebug>

Backend::Backend(QQmlEngine *engine, QObject *parent) : QObject(parent), m_engine(engine)
{
}

void Backend::launchTerminal()
{
    QString flutterAppPath = QDir::cleanPath(QCoreApplication::applicationDirPath() + "/../../flutter_app/build/linux/x64/release/bundle/sist_ui");
    QProcess *process = new QProcess(this);
    process->start(flutterAppPath);
    // Optionally, connect to finished signal to clean up or log
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [process](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitCode);
        Q_UNUSED(exitStatus);
        process->deleteLater();
    });
}

void Backend::launchBrowser()
{
    QProcess *process = new QProcess(this);
    process->start("chromium-browser"); // Or "google-chrome", "firefox", etc.
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [process](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitCode);
        Q_UNUSED(exitStatus);
        process->deleteLater();
        qDebug() << "Browser process finished.";
    });
}

void Backend::launchFileManager()
{
    QProcess *process = new QProcess(this);
    process->start("nautilus"); // Or "dolphin", "thunar", etc.
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [process](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitCode);
        Q_UNUSED(exitStatus);
        process->deleteLater();
        qDebug() << "File Manager process finished.";
    });
}
