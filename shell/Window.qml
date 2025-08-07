import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: window
    visible: true
    width: 800
    height: 600
    flags: Qt.FramelessWindowHint | Qt.Window

    property alias title: titleText.text

    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"
        border.color: "#d7c9a7"
        border.width: 1

        // Title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: 40
            color: "transparent"

            Image {
                source: "qrc:/theme/theme_assets/window/window_titlebar_background.png"
                anchors.fill: parent
                fillMode: Image.Tile
            }

            Text {
                id: titleText
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 16
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Buttons
                Button {
                    width: 32
                    height: 32
                    background: Image {
                        source: "qrc:/theme/theme_assets/window/window_minimize_normal.png"
                    }
                    onClicked: window.showMinimized()
                }
                Button {
                    width: 32
                    height: 32
                    background: Image {
                        source: "qrc:/theme/theme_assets/window/window_maximize_normal.png"
                    }
                    onClicked: window.visibility === Window.Maximized ? window.showNormal() : window.showMaximized()
                }
                Button {
                    width: 32
                    height: 32
                    background: Image {
                        source: "qrc:/theme/theme_assets/window/window_close_normal.png"
                    }
                    onClicked: window.close()
                }
            }

            MouseArea {
                anchors.fill: parent
                property point lastMousePos
                onPressed: lastMousePos = Qt.point(mouse.x, mouse.y)
                onPositionChanged: {
                    var delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y)
                    window.x += delta.x
                    window.y += delta.y
                }
            }
        }

        // Content
        Item {
            id: contentItem
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }
}
