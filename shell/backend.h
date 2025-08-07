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

private:
    QQmlEngine *m_engine;
};

#endif // BACKEND_H
