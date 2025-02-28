#include "iconchanger.h"
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDebug>

IconChanger::IconChanger(QObject *parent) : QObject(parent) {}

void IconChanger::changeIcon(const QString &newIconPath) {
    QString desktopFilePath = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
                              + "/myapp.desktop";  // Adjust as needed

    QFile file(desktopFilePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open .desktop file";
        return;
    }

    QStringList lines;
    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.startsWith("Icon=")) {
            line = "Icon=" + newIconPath;
        }
        lines.append(line);
    }
    file.close();

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Failed to write to .desktop file";
        return;
    }

    QTextStream out(&file);
    for (const QString &line : lines) {
        out << line << "\n";
    }
    file.close();

    qDebug() << "Icon updated to:" << newIconPath;
}
