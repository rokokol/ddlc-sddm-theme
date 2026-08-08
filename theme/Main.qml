import QtQuick
import "components"

// SDDM theme in the style of Doki Doki Literature Club.
// Layers bottom to top: dot background → easter-egg darkening → clock →
// character sprites → login panel → bottom corners → glitch over everything
Rectangle {
    id: root

    // Defaults for test-mode; in the real greeter SDDM sets the size
    width: 1280
    height: 720

    // The background answers failures: the 1st and 2nd darken it, the 3rd turns it black
    color: justMonika ? "black" : Qt.darker(config.bgColor, 1 + failCount * 0.13)
    Behavior on color {
        ColorAnimation {
            duration: 3000
        }
    }

    property int failCount: 0
    readonly property bool justMonika: failCount >= 3

    // Wrong-password reaction. Called from onLoginFailed and by F8: test-mode has
    // no daemon, so sddm.loginFailed never arrives and there would be no other way
    // to preview the glitch and the easter egg.
    // failCount++ lives in glitch.onFinished — the phase changes (grain, dot
    // deformation, Yuri's -cut/-distorted sprites) land after the glitch
    function showFail() {
        forgiveTimer.restart()
        panel.clearPassword()
        glitch.trigger()
    }

    DotsBackground {
        anchors.fill: parent
        z: 0
        corrupted: root.justMonika
        rough: root.failCount >= 2
    }

    // Background grain from the 1st failure on
    GrainOverlay {
        anchors.fill: parent
        z: 1
        active: root.failCount >= 1
    }

    // Clock
    Text {
        id: clockText

        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        font.family: config.font
        font.pixelSize: 44
        color: config.deepPink
        text: Qt.formatTime(new Date(), "hh:mm")
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
    }

    SpriteRow {
        id: sprites

        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // Sprites stand above the bottom buttons and never overlap them
        anchors.bottomMargin: 88
        failCount: root.failCount
        sideReserve: Math.max(leftControls.width, rightControls.width) + 40
    }

    LoginPanel {
        id: panel

        z: 3
        anchors.centerIn: parent
        onLoginRequested: function(username, password) {
            sddm.login(username, password, sessions.currentIndex)
        }
    }

    // Bottom left corner: session and keyboard layout
    Row {
        id: leftControls

        z: 4
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        SessionSelector {
            id: sessions
        }

        // Layout switch: a click cycles through them.
        // Hidden when there are no layouts — in test-mode, for one
        Rectangle {
            readonly property bool hasLayouts: typeof keyboard !== "undefined" && keyboard.layouts.length > 0

            visible: hasLayouts
            width: 44
            height: 44
            radius: width / 2
            color: layoutArea.containsMouse ? config.accentPink : "white"
            border.color: config.accentPink
            border.width: 2
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                font.family: config.font
                font.pixelSize: 14
                color: layoutArea.containsMouse ? "white" : config.deepPink
                text: parent.hasLayouts
                      ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase()
                      : ""
            }

            MouseArea {
                id: layoutArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    // Bottom right corner: suspend, reboot, power off
    Row {
        id: rightControls

        z: 4
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        PowerButton {
            glyph: ""
            visible: sddm.canSuspend
            onActivated: sddm.suspend()
        }
        PowerButton {
            glyph: ""
            visible: sddm.canReboot
            onActivated: sddm.reboot()
        }
        PowerButton {
            glyph: ""
            visible: sddm.canPowerOff
            onActivated: sddm.powerOff()
        }
    }

    // Just Monika popups above everything but the glitch
    MonikaPopups {
        z: 6
        anchors.fill: parent
        active: root.justMonika
    }

    GlitchOverlay {
        id: glitch

        z: 10
        anchors.fill: parent
        target: panel
        // Phase changes (failCount++) land after the glitch animation, so the
        // background corruption and the sprite swap don't overlap it
        onFinished: root.failCount++
    }

    // The easter egg resets itself after a minute of silence
    Timer {
        id: forgiveTimer

        interval: 60000
        onTriggered: root.failCount = 0
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.showFail()
        }

        function onLoginSucceeded() {
            root.failCount = 0
        }
    }

    // F8 previews the glitch — three presses reach the easter egg
    Shortcut {
        sequence: "F8"
        context: Qt.ApplicationShortcut
        onActivated: root.showFail()
    }
}
