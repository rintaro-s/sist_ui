import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    visible: true
    width: 1920
    height: 1080
    title: "SIST UI"

    Image {
        id: wallpaper
        source: "qrc:/theme/theme_assets/desktop/wallpaper.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: taskbar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 70 // Increased height for better visuals
        
        Image {
            source: "qrc:/theme/theme_assets/desktop/taskbar_background.png"
            anchors.fill: parent
            fillMode: Image.Tile
        }

        Row {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "SIST"
                color: "white"
                font.pixelSize: 20
            }

            Button {
                text: "Terminal"
                onClicked: {
                    backend.launchTerminal()
                }
            }
        }
    }
}
