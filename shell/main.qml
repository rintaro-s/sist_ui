import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0
import QtMultimedia 5.15

Window {
    id: root
    visible: true
    width: 1920
    height: 1080
    title: "SIST UI - Blue Archive Style"

    // --- Asset Paths ---
    property string wallpaperPath: "qrc:/theme_assets/desktop/wallpaper.png"
    property string characterPath: "qrc:/flutter_app/assets/character.png"

    // --- Font Loader ---
    FontLoader { id: ktegakiFont; source: "qrc:/flutter_app/assets/fonts/KTEGAKI.ttf" }

    // --- Parallax Background ---
    Item {
        id: parallaxContainer
        anchors.fill: parent

        // Mouse area to track cursor position for parallax effect
        MouseArea {
            id: parallaxMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }

        // Layer 1: Wallpaper (moves the least)
        Image {
            id: wallpaper
            source: wallpaperPath
            anchors.fill: parent
            fillMode: Image.Crop

            // Parallax calculation
            transform: Translate {
                x: (parallaxMouseArea.mouseX / root.width - 0.5) * -20
                y: (parallaxMouseArea.mouseY / root.height - 0.5) * -10
                Behavior on x { PropertyAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }

            // Subtle blur effect to enhance depth
            layer.enabled: true
            layer.effect: FastBlur {
                radius: 5 // Adjust blur strength as needed
                source: wallpaper
            }
        }

        // Layer 2: Character (moves the most)
        Image {
            id: character
            source: characterPath
            width: parent.height * 0.8 // Adjust size relative to screen height
            height: parent.height * 0.8
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 50
            fillMode: Image.PreserveAspectFit

            // Parallax calculation
            transform: Translate {
                x: (parallaxMouseArea.mouseX / root.width - 0.5) * 40
                y: (parallaxMouseArea.mouseY / root.height - 0.5) * 20
                Behavior on x { PropertyAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }

            // Idle animation: subtle floating
            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                PropertyAnimation { from: character.y; to: character.y - 5; duration: 2000; easing.type: Easing.InOutSine }
                PropertyAnimation { from: character.y - 5; to: character.y; duration: 2000; easing.type: Easing.InOutSine }
            }
        }
    }

    // --- UI Overlay ---
    Item {
        id: uiOverlay
        anchors.fill: parent

        // Top-Right HUD: Clock and Date
        Column {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 5
            
            Text {
                id: clockText
                color: "white"
                font.family: ktegakiFont.name
                font.pixelSize: 48
                font.weight: Font.Bold
                text: Qt.formatTime(new Date(), "hh:mm")
            }
            Text {
                color: "white"
                font.family: ktegakiFont.name
                font.pixelSize: 24
                text: Qt.formatDate(new Date(), "yyyy/MM/dd")
            }

            Text {
                id: cpuUsageText
                color: "white"
                font.family: ktegakiFont.name
                font.pixelSize: 20
                text: "CPU: --%"
            }

            Text {
                id: memUsageText
                color: "white"
                font.family: ktegakiFont.name
                font.pixelSize: 20
                text: "MEM: --%"
            }

            // Timer to update the clock and system info every second
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    clockText.text = Qt.formatTime(new Date(), "hh:mm")
                    cpuUsageText.text = "CPU: " + backend.getCpuUsage().toFixed(1) + "%";
                    memUsageText.text = "MEM: " + backend.getMemoryUsage().toFixed(1) + "%";
                }
            }
        }

        // Sound Effects
        SoundEffect {
            id: clickSound
            source: "qrc:/sounds/click.wav" // Placeholder for a click sound
        }
        SoundEffect {
            id: selectSound
            source: "qrc:/sounds/select.wav" // Placeholder for a select sound
        }

        // App Launcher Carousel
        PathView {
            id: appCarousel
            anchors.fill: parent
            path: Path {
                startX: -200
                startY: root.height / 2
                PathArc {
                    x: root.width + 200
                    y: root.height / 2
                    radiusX: root.width * 1.2
                    radiusY: root.height * 0.8
                    useLargeArc: true
                    direction: PathArc.Clockwise
                }
            }

            model: backend.getApplications()

            delegate: Item {
                id: delegateItem
                width: 180 // Slightly wider to accommodate glow/background
                height: 220 // Slightly taller

                property bool isCurrent: PathView.isCurrentItem

                // Background for the app icon and text
                Rectangle {
                    id: appBackground
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    radius: 15 // Rounded corners
                    color: "#2a2a2a" // Dark background
                    opacity: isCurrent ? 0.8 : 0.4 // More visible when current
                    border.color: isCurrent ? "#FFD700" : "transparent" // Gold border when current
                    border.width: isCurrent ? 2 : 0

                    Behavior on opacity { PropertyAnimation { duration: 200 } }
                    Behavior on border.width { PropertyAnimation { duration: 200 } }
                    Behavior on border.color { PropertyAnimation { duration: 200 } }
                }

                // Glow effect for the current item
                Glow {
                    anchors.fill: appBackground
                    source: appBackground
                    radius: isCurrent ? 25 : 0 // Larger radius when current
                    color: "#FFD700" // Gold glow
                    spread: isCurrent ? 0.2 : 0
                    visible: isCurrent // Only visible when current
                    Behavior on radius { PropertyAnimation { duration: 250 } }
                    Behavior on spread { PropertyAnimation { duration: 250 } }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        id: appIcon
                        source: icon // 'icon' comes from the model data
                        width: 128
                        height: 128
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: name // 'name' comes from the model data
                        color: "white"
                        font.family: ktegakiFont.name
                        font.pixelSize: 22
                        Layout.alignment: Qt.AlignHCenter
                        visible: isCurrent
                        // Add subtle text shadow for readability
                        layer.enabled: true
                        layer.effect: DropShadow {
                            color: "#000000"
                            radius: 5
                            samples: 10
                            horizontalOffset: 2
                            verticalOffset: 2
                        }
                    }
                }

                scale: isCurrent ? 1.2 : 0.8
                opacity: isCurrent ? 1.0 : 0.6
                z: isCurrent ? 2 : 1

                // More game-like easing
                Behavior on scale { PropertyAnimation { duration: 300; easing.type: Easing.OutElastic } }
                Behavior on opacity { PropertyAnimation { duration: 250; easing.type: Easing.OutBack } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (isCurrent) {
                            backend.executeCommand(exec); // 'exec' comes from the model data
                            selectSound.play();
                        } else {
                            // If not current, make it current when clicked
                            appCarousel.currentIndex = index;
                            clickSound.play();
                        }
                    }
                }
            }

            // Make it interactive
            MouseArea {
                anchors.fill: parent
                property real lastMouseX: -1

                onPressed: lastMouseX = mouse.x
                onPositionChanged: {
                    if (lastMouseX !== -1) {
                        var delta = mouse.x - lastMouseX;
                        appCarousel.position -= delta * 0.001; // Adjust sensitivity
                        lastMouseX = mouse.x;
                    }
                }
                onReleased: lastMouseX = -1
            }

            Keys.onLeftPressed: appCarousel.decrementCurrentIndex()
            Keys.onRightPressed: appCarousel.incrementCurrentIndex()

            WheelArea {
                anchors.fill: parent
                onWheel: {
                    if (wheel.angleDelta.y > 0) {
                        appCarousel.decrementCurrentIndex()
                    } else {
                        appCarousel.incrementCurrentIndex()
                    }
                }
            }
        }
        // Bottom Dock
        Rectangle {
            id: dock
            width: parent.width
            height: 100
            anchors.bottom: parent.bottom
            color: "#00000088" // Semi-transparent black

            RowLayout {
                anchors.centerIn: parent
                spacing: 25

                // Dock Icons
                Component {
                    id: dockButtonDelegate
                    Button {
                        property string iconSource
                        property alias action: onClicked

                        width: 72
                        height: 72
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: iconSource
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        scale: control.pressed ? 0.9 : (control.hovered ? 1.1 : 1.0)
                        Behavior on scale { PropertyAnimation { duration: 150; easing.type: Easing.OutBack } }

                        onClicked: clickSound.play()
                    }
                }

                Loader { sourceComponent: dockButtonDelegate; onLoaded: { item.iconSource = "qrc:/theme_assets/icons/icon_terminal.png"; item.action.connect(backend.launchTerminal) } }
                Loader { sourceComponent: dockButtonDelegate; onLoaded: { item.iconSource = "qrc:/theme_assets/icons/icon_app_default.png"; item.action.connect(backend.launchBrowser) } }
                Loader { sourceComponent: dockButtonDelegate; onLoaded: { item.iconSource = "qrc:/theme_assets/icons/icon_folder.png"; item.action.connect(backend.launchFileManager) } }
            }
        }
    }
}