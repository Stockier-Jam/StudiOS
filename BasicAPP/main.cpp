#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "iconchanger.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    IconChanger iconChanger;
    engine.rootContext()->setContextProperty("iconChanger", &iconChanger);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
