import QtQuick

// Wrong-password glitch: the panel shakes, RGB-split, random scanlines and
// flickering corrupted text. All of it dies out after ~0.8 s
Item {
    id: overlay

    property Item target
    readonly property bool rgbSplit: String(config.glitchRgbSplit) === "true"
    property bool active: false

    signal finished()

    visible: active

    function trigger() {
        active = true
        stopTimer.restart()
    }

    // Shake the panel and reseed the noise every 40 ms
    Timer {
        id: shakeTimer

        interval: 40
        repeat: true
        running: overlay.active
        onTriggered: {
            if (overlay.target) {
                overlay.target.anchors.horizontalCenterOffset = Math.round((Math.random() - 0.5) * 14)
                overlay.target.anchors.verticalCenterOffset = Math.round((Math.random() - 0.5) * 10)
            }
            noise.reseed()
            corrupt.reseed()
        }
    }

    Timer {
        id: stopTimer

        interval: 800
        onTriggered: {
            overlay.active = false
            if (overlay.target) {
                overlay.target.anchors.horizontalCenterOffset = 0
                overlay.target.anchors.verticalCenterOffset = 0
            }
            overlay.finished()
        }
    }

    // RGB-split lives in its own file: if QtQuick.Effects is unavailable only this
    // Loader breaks and the rest of the glitch keeps working
    Loader {
        anchors.fill: parent
        source: overlay.rgbSplit ? "RgbSplit.qml" : ""
        onLoaded: {
            item.target = overlay.target
            item.active = Qt.binding(function() { return overlay.active })
        }
    }

    // Random horizontal scanlines
    Item {
        id: noise

        anchors.fill: parent

        function reseed() {
            for (var i = 0; i < lines.count; i++)
                lines.itemAt(i).reseed()
        }

        Repeater {
            id: lines

            model: 14

            Rectangle {
                function reseed() {
                    y = Math.random() * overlay.height
                    height = 1 + Math.random() * 5
                    opacity = 0.25 + Math.random() * 0.5
                    color = Math.random() < 0.5 ? config.glitchPink : (Math.random() < 0.5 ? config.glitchCyan : config.glitchDark)
                    x = -20 + Math.random() * 40
                }

                width: overlay.width + 40
                Component.onCompleted: reseed()
            }
        }
    }

    // Flickering corrupted text: the plain wrong-password glitch, without
    // "Just Monika" — that one belongs to the popup easter egg
    Text {
        id: corrupt

        readonly property var pool: ["░▒▓ ACCESS DENIED ▓▒░", "̷̛͘͝?̸?̵?̶?̷?̸?̵?̶?̷", "err0r", "▓▒░ 01000101 ░▒▓", "n̷u̸l̶l̵"]

        function reseed() {
            if (Math.random() < 0.25)
                text = pool[Math.floor(Math.random() * pool.length)]
            visible = Math.random() < 0.7
            anchors.horizontalCenterOffset = Math.round((Math.random() - 0.5) * 30)
        }

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.24
        text: pool[0]
        font.family: config.font
        font.pixelSize: 26
        opacity: 0.75
        color: config.deepPink
        style: Text.Outline
        styleColor: config.corruptOutline
    }
}
