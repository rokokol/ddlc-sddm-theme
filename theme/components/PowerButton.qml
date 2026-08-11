import QtQuick

// Round power/session button in the bottom corner: white with a pink border,
// fills pink and grows a little on hover
Rectangle {
    id: btn

    property string glyph
    signal activated()

    width: 48
    height: 48
    radius: width / 2
    color: area.containsMouse ? config.accentPink : config.textLight
    border.color: config.accentPink
    border.width: 2

    scale: area.pressed ? 0.92 : (area.containsMouse ? 1.08 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 110
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        font.family: config.iconFont
        font.pixelSize: 20
        color: area.containsMouse ? config.textLight : config.deepPink
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }
}
