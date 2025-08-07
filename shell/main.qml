import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Window {
    visible: true
    width: 1920
    height: 1080
    title: "SIST UI"

    FontLoader { id: ktegakiFont; source: "qrc:///flutter_app/assets/fonts/KTEGAKI.ttf" }

    Image {
        id: wallpaper
        source: "qrc:/theme_assets/desktop/wallpaper.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    // Application Launcher
    GridView {
        id: appLauncher
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 50
        anchors.leftMargin: 50
        width: 200
        height: parent.height - taskbar.height - 100
        cellWidth: 100
        cellHeight: 100

        model: ListModel {
            ListElement { name: "Terminal"; icon: "qrc:/theme_assets/icons/icon_terminal.png"; action: "backend.launchTerminal()" }
            ListElement { name: "Settings"; icon: "qrc:/theme_assets/icons/icon_settings.png"; action: "console.log('Settings clicked')" }
            ListElement { name: "Game"; icon: "qrc:/theme_assets/icons/icon_app_default.png"; action: "console.log('Game clicked')" }
            // Add more applications here
        }

        delegate: Item {
            width: appLauncher.cellWidth
            height: appLauncher.cellHeight

            Column {
                anchors.centerIn: parent
                spacing: 5

                Button {
                    width: 64
                    height: 64
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Image {
                        source: icon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    onClicked: {
                        eval(action)
                    }
                }

                Text {
                    text: name
                    color: "white"
                    font.family: ktegakiFont.name
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Rectangle {
        id: taskbar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 80 // Increased height for better visuals
        color: "transparent" // Make it transparent to show the background image
        
        Image {
            source: "qrc:/theme_assets/desktop/taskbar_background.png"
            anchors.fill: parent
            fillMode: Image.Stretch // Stretch to fill the taskbar
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            spacing: 20

            Text {
                text: "SIST"
                color: "white"
                font.family: ktegakiFont.name
                font.pixelSize: 30
                Layout.preferredWidth: 100
            }

            // Taskbar Applications
            Repeater {
                model: ListModel {
                    ListElement { name: "Terminal"; icon: "qrc:/theme_assets/icons/icon_terminal.png"; action: "backend.launchTerminal()" }
                    ListElement { name: "Settings"; icon: "qrc:/theme_assets/icons/icon_settings.png"; action: "console.log('Settings clicked')" }
                    ListElement { name: "Game"; icon: "qrc:/theme_assets/icons/icon_app_default.png"; action: "console.log('Game clicked')" }
                }

                delegate: Button {
                    width: 64
                    height: 64
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Image {
                        source: icon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    onClicked: {
                        eval(action)
                    }
                }
            }
        }
    }
}
