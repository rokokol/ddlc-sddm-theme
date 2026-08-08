import QtQuick

// A single character: drifts left and right inside its band [xMin, xMax], hops
// on hover and switches to the excited sticker.
// In easter-egg mode (frozen) the drift stops: Monika slides to the centre and
// everyone else fades out (gone).
// Every sticker shares one 141x173 canvas, bottom-aligned: the characters keep their relative
// sizes, their feet line up, and nobody shrinks when a consumer scales by width instead.
// Height comes from the owner (SpriteRow), which knows the canvas — set it, or nothing draws
Item {
    id: sprite

    property url calmSource
    property url excitedSource
    // Cut (-cut) sprites — Yuri, from the 1st failure
    property url cutCalmSource
    property url cutExcitedSource
    property bool cut: false
    // Distorted sprites — Yuri, from the 2nd failure; distorted picks these
    property url distortedCalmSource
    property url distortedExcitedSource
    property bool distorted: false
    property real xMin: 0
    property real xMax: 200
    property int driftDuration: 9000
    property bool frozen: false
    property bool isMonika: false
    property real centerTo: 0
    property bool gone: false

    property bool selfExcited: false
    readonly property bool excitedNow: hoverArea.containsMouse || selfExcited

    // Mirror the sprite along the direction of travel
    property real prevX: x
    property bool movingRight: false
    onXChanged: {
        if (Math.abs(x - prevX) > 0.5) {
            movingRight = x > prevX
            prevX = x
        }
    }

    width: img.width

    opacity: gone ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 1600
        }
    }
    visible: opacity > 0

    x: xMin

    SequentialAnimation on x {
        id: drift

        running: !sprite.frozen
        loops: Animation.Infinite

        NumberAnimation {
            to: sprite.xMax
            duration: sprite.driftDuration
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: sprite.xMin
            duration: sprite.driftDuration
            easing.type: Easing.InOutSine
        }
    }

    onFrozenChanged: {
        if (frozen) {
            drift.stop()
            if (isMonika)
                centerAnim.restart()
        } else {
            centerAnim.stop()
            drift.restart()
        }
    }

    NumberAnimation {
        id: centerAnim

        target: sprite
        property: "x"
        to: sprite.centerTo
        duration: 1800
        easing.type: Easing.InOutQuad
    }

    Image {
        id: img

        source: sprite.distorted
                ? (sprite.excitedNow ? sprite.distortedExcitedSource : sprite.distortedCalmSource)
                : sprite.cut
                  ? (sprite.excitedNow ? sprite.cutExcitedSource : sprite.cutCalmSource)
                  : (sprite.excitedNow ? sprite.excitedSource : sprite.calmSource)
        height: sprite.height
        width: sourceSize.height > 0 ? height * sourceSize.width / sourceSize.height : height
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        mirror: sprite.movingRight
    }

    // Hop: sharp on the way up, bouncy on the way down
    SequentialAnimation {
        id: jump

        NumberAnimation {
            target: img
            property: "y"
            to: -42
            duration: 190
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: img
            property: "y"
            to: 0
            duration: 480
            easing.type: Easing.OutBounce
        }
        onFinished: sprite.selfExcited = false
    }

    function hop(excite) {
        if (jump.running)
            return
        if (excite)
            selfExcited = true
        jump.start()
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: sprite.hop(false)
    }
}
