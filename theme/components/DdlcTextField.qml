import QtQuick
import QtQuick.Controls.Basic

// A DDLC-style input: a white "pill" with a pink border that darkens on focus
TextField {
    id: field

    // Height comes from the font metrics, not from the content: otherwise the
    // password field resizes as you type (echoMode dots carry different metrics
    // than the placeholder) and jerks the backdrop. This way the height is stable
    // and still follows a change of font or size
    FontMetrics {
        id: fm

        font: field.font
    }
    height: Math.ceil(fm.height) + topPadding + bottomPadding

    font.family: config.font
    font.pixelSize: 19
    color: config.textDark
    placeholderTextColor: "#C9A0B4"
    selectionColor: config.accentPink
    selectedTextColor: "white"
    leftPadding: 18
    rightPadding: 18
    topPadding: 10
    bottomPadding: 10

    background: Rectangle {
        radius: height / 2
        color: "white"
        border.color: field.activeFocus ? config.deepPink : config.accentPink
        border.width: 2
    }
}
