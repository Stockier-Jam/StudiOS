#ifndef ICONCHANGER_H
#define ICONCHANGER_H

#include <QObject>
#include <QString>

class IconChanger : public QObject {
    Q_OBJECT
public:
    explicit IconChanger(QObject *parent = nullptr);

    Q_INVOKABLE void changeIcon(const QString &newIconPath);
};

#endif // ICONCHANGER_H
