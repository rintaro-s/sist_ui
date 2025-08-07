#ifndef FLUTTEREMBEDDER_H
#define FLUTTEREMBEDDER_H

#include <QObject>
#include <QWindow>

// Forward declaration to avoid including the heavy Flutter header here
struct _FlViewController;

class FlutterEmbedder : public QObject
{
    Q_OBJECT
public:
    explicit FlutterEmbedder(QObject *parent = nullptr);
    ~FlutterEmbedder();

    Q_INVOKABLE void embedFlutter(QWindow *window, const QString& projectPath, const QString& icuDataPath);

private:
    _FlViewController* m_flutterViewController = nullptr;
};

#endif // FLUTTEREMBEDDER_H
