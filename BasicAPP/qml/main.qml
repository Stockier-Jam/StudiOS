import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width: 400
    height: 600
    title: "Ubuntu Touch App"

    Column {
        anchors.centerIn: parent
        spacing: 20

        Button {
            text: "Change Icon"
            onClicked: iconChanger.changeIcon("/home/phablet/.local/share/applications/my_new_icon.png")
        }
    }
}
