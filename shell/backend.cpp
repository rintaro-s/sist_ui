#include "backend.h"
#include <QQmlComponent>
#include <QQuickWindow>
#include <QDir>

Backend::Backend(QQmlEngine *engine, QObject *parent) : QObject(parent), m_engine(engine)
{
}

void Backend::launchTerminal()
{
    // Define the paths needed for the Flutter engine
    QString projectPath = QDir::cleanPath("../flutter_app/build/linux/x64/release/bundle");
    QString icuDataPath = QDir::cleanPath("../flutter_app/build/linux/x64/release/bundle/data/icudtl.dat");
    
    createWindow("Terminal", projectPath, icuDataPath);
}

void Backend::createWindow(const QString &title, const QString &projectPath, const QString& icuDataPath)
{
    QQmlComponent component(m_engine, QUrl("qrc:/Window.qml"));
    QObject *object = component.create();
    QQuickWindow *window = qobject_cast<QQuickWindow*>(object);

    if (window) {
        window->setProperty("title", title);
        // Embed the Flutter content into the newly created QML window
        m_flutterEmbedder.embedFlutter(window, projectPath, icuDataPath);
        window->show();
    } else {
        if(object) delete object;
        // Handle error: component creation failed
    }
}
