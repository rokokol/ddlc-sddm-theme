pragma Singleton
import QtQuick

// The one place that turns config.font and config.bodyFont into a family and a weight.
// A missing family does not fall back to another named family in QML, so the choice is made here
QtObject {
    // The bundled file registers its own family name, so a login screen without session fonts
    // still has Nunito
    readonly property FontLoader bundled: FontLoader {
        source: "Nunito-wght.ttf"
    }

    // Doki is personal-use only and is never shipped, so it is looked up among the installed
    // families. Qt.fontFamilies() lists the system fonts, not the bundled one
    readonly property bool displayInstalled: Qt.fontFamilies().indexOf(config.font) !== -1

    // Sets the family and weight of an item's font. "display" is Doki when installed, with its
    // own weight, and Nunito Black otherwise. "body" is Nunito Medium
    function apply(item, role) {
        const display = role === "display"
        const own = display && displayInstalled
        const weight = own ? Font.Normal : (display ? Font.Black : Font.Medium)

        item.font.family = display ? (displayInstalled ? config.font : bundled.name) : config.bodyFont
        item.font.weight = weight
        // The bundled file is one variable font, and Qt picks a weight from it only through its
        // axis. Older Qt has no such property, so it is set here and not in the QML of the item,
        // where an unknown property would stop the whole theme from loading
        if (!own)
            item.font.variableAxes = { "wght": weight }
    }
}
