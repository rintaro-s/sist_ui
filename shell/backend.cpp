#include "backend.h"
#include <QProcess>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>

Backend::Backend(QQmlEngine *engine, QObject *parent) : QObject(parent), m_engine(engine)
{
}

// Helper function to launch a process and handle errors
void Backend::launchProcess(const QString &program, const QStringList &arguments)
{
    QProcess *process = new QProcess(this);

    connect(process, &QProcess::errorOccurred, this, [=](QProcess::ProcessError error){
        qWarning() << "Failed to start" << program << ":" << error;
        process->deleteLater();
    });

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [=](int exitCode, QProcess::ExitStatus exitStatus) {
        if (exitStatus == QProcess::CrashExit) {
            qWarning() << program << "crashed.";
        }
        qDebug() << program << "finished with exit code" << exitCode;
        process->deleteLater();
    });

    process->start(program, arguments);
}


void Backend::launchTerminal()
{
    // 1. Try to launch a preferred terminal, then fall back to generic ones.
    //    This provides a better experience on different systems.
    QStringList terminals = {"xfce4-terminal", "konsole", "gnome-terminal", "lxterminal", "xterm"};
    for (const QString &terminal : terminals) {
        if (QStandardPaths::findExecutable(terminal).isEmpty()) {
            continue;
        }
        qDebug() << "Launching terminal:" << terminal;
        launchProcess(terminal, QStringList());
        return;
    }
    qWarning() << "No suitable terminal found.";
}

void Backend::launchBrowser()
{
    qDebug() << "Launching default web browser...";
    // Use xdg-open to launch the user's default browser.
    // This is the standard way on most Linux desktops.
    launchProcess("xdg-open", {"https://www.google.com"});
}

void Backend::launchFileManager()
{
    qDebug() << "Launching default file manager...";
    // Use xdg-open to launch the default file manager for the home directory.
    QString homePath = QDir::homePath();
    launchProcess("xdg-open", {homePath});
}

QVariantList Backend::getApplications()
{
    QVariantList applications;
    QStringList appDirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);

    qDebug() << "Searching for .desktop files in:" << appDirs;

    for (const QString &appDir : appDirs) {
        QDirIterator it(appDir, QStringList() << "*.desktop", QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString filePath = it.next();
            QSettings desktopFile(filePath, QSettings::IniFormat);
            desktopFile.beginGroup("Desktop Entry");

            // Skip if NoDisplay or Hidden is true
            if (desktopFile.value("NoDisplay").toBool() || desktopFile.value("Hidden").toBool()) {
                desktopFile.endGroup();
                continue;
            }

            QString name = desktopFile.value("Name").toString();
            QString icon = desktopFile.value("Icon").toString();
            QString exec = desktopFile.value("Exec").toString();

            desktopFile.endGroup();

            if (name.isEmpty() || exec.isEmpty()) {
                continue; // Skip invalid entries
            }

            // Clean up Exec string (remove %u, %f, etc.)
            exec.remove(QRegExp(" %[fFuUcdiIkK]"));

            QVariantMap app;
            app["name"] = name;
            app["icon"] = icon;
            app["exec"] = exec;
            applications.append(app);

            qDebug() << "Found app:" << name << ", Icon:" << icon << ", Exec:" << exec;
        }
    }
    return applications;
}

void Backend::executeCommand(const QString &command)
{
    qDebug() << "Executing command:" << command;
    launchProcess(command, QStringList());
}

double Backend::getCpuUsage()
{
    QFile file("/proc/stat");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open /proc/stat";
        return 0.0;
    }

    QTextStream in(&file);
    QString line = in.readLine();
    file.close();

    // Expected format: cpu user nice system idle iowait irq softirq steal guest guest_nice
    QRegularExpression re("cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)");
    QRegularExpressionMatch match = re.match(line);

    if (match.hasMatch()) {
        long long user = match.captured(1).toLongLong();
        long long nice = match.captured(2).toLongLong();
        long long system = match.captured(3).toLongLong();
        long long idle = match.captured(4).toLongLong();

        long long totalCpuTime = user + nice + system + idle;
        long long idleCpuTime = idle;

        double cpuUsage = 0.0;
        if (m_lastTotalCpuTime != 0) {
            long long totalDiff = totalCpuTime - m_lastTotalCpuTime;
            long long idleDiff = idleCpuTime - m_lastIdleCpuTime;
            if (totalDiff > 0) {
                cpuUsage = (double)(totalDiff - idleDiff) / totalDiff * 100.0;
            }
        }

        m_lastTotalCpuTime = totalCpuTime;
        m_lastIdleCpuTime = idleCpuTime;

        return cpuUsage;
    }
    return 0.0;
}

double Backend::getMemoryUsage()
{
    QFile file("/proc/meminfo");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open /proc/meminfo";
        return 0.0;
    }

    QTextStream in(&file);
    long long totalMem = 0;
    long long availableMem = 0;

    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.startsWith("MemTotal:")) {
            totalMem = line.section(' ', -2, -2).toLongLong();
        } else if (line.startsWith("MemAvailable:")) {
            availableMem = line.section(' ', -2, -2).toLongLong();
        }
    }
    file.close();

    if (totalMem > 0) {
        return (double)(totalMem - availableMem) * 100.0 / totalMem;
    }
    return 0.0;
}
