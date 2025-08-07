#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QQmlEngine>
#include "flutter_embedder.h"

class Backend : public QObject
{
    Q_OBJECT
public:
    explicit Backend(QQmlEngine *engine, QObject *parent = nullptr);

    Q_INVOKABLE void launchTerminal();

private:
    void createWindow(const QString &title, const QString &projectPath, const QString& icuDataPath);

    QQmlEngine *m_engine;
    FlutterEmbedder m_flutterEmbedder;
};

#endif // BACKEND_H
