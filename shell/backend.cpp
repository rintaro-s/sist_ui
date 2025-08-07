#include "backend.h"
#include <QProcess>
#include <QDir>

Backend::Backend(QQmlEngine *engine, QObject *parent) : QObject(parent), m_engine(engine)
{
}

void Backend::launchTerminal()
{
    QString flutterAppPath = QDir::cleanPath("/usr/share/sist-ui/flutter_app/bundle/sist_ui");
    QProcess *process = new QProcess(this);
    process->start(flutterAppPath);
    // Optionally, connect to finished signal to clean up or log
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [process](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitCode);
        Q_UNUSED(exitStatus);
        process->deleteLater();
    });
}
