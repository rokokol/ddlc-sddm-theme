import QtQuick

// Login button: the text "OK" with a thick purple outline on a transparent
// background, like the button in the game. The outline is eight offset copies of
// the text, because Text.Outline draws too thin a line
Item {
    id: btn

    signal clicked()

    readonly property string label: "OK"
    readonly property color outline: config.okOutline

    width: okText.implicitWidth + 28
    height: okText.implicitHeight + 12

    scale: area.pressed ? 0.92 : (area.containsMouse ? 1.1 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    Repeater {
        model: [[-3, 0], [3, 0], [0, -3], [0, 3], [-2, -2], [2, -2], [-2, 2], [2, 2]]

        Text {
            x: (btn.width - implicitWidth) / 2 + modelData[0]
            y: (btn.height - implicitHeight) / 2 + modelData[1]
            text: btn.label
            font.family: config.font
            font.pixelSize: 36
            font.bold: true
            font.letterSpacing: 6
            color: btn.outline
        }
    }

    Text {
        id: okText

        anchors.centerIn: parent
        text: btn.label
        font.family: config.font
        font.pixelSize: 36
        font.bold: true
        font.letterSpacing: 6
        color: "white"
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        // PointingHandCursor — in the bundled cursor theme that is Sayori's glitched head
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
