import QtQuick

// The row of four characters above the bottom buttons. Each drifts strictly
// inside its own band — bands never overlap and never reach the corner zones —
// so no sprite leaves the screen or runs into another one or into the UI
Item {
    id: row

    property int failCount: 0
    readonly property bool justMonika: failCount >= 3
    // Width of the bottom corner zones: session buttons left, power right
    property real sideReserve: 240

    height: 172

    readonly property var girls: ["sayori", "monika", "natsuki", "yuri"]

    Repeater {
        id: rep

        model: row.girls

        CharacterSprite {
            readonly property real bandW: Math.max(172, (row.width - 2 * row.sideReserve) / row.girls.length)

            calmSource: "../assets/" + modelData + "-sticker-calm.png"
            excitedSource: "../assets/" + modelData + "-sticker-excited.png"
            // From the 1st failure Yuri switches to the cut (-cut) sprites
            cutCalmSource: modelData === "yuri" ? "../assets/yuri-sticker-calm-cut.png" : ""
            cutExcitedSource: modelData === "yuri" ? "../assets/yuri-sticker-excited-cut.png" : ""
            cut: modelData === "yuri" && row.failCount >= 1
            // From the 2nd failure Yuri switches to the distorted sprites
            distortedCalmSource: modelData === "yuri" ? "../assets/yuri-sticker-distorted-calm.png" : ""
            distortedExcitedSource: modelData === "yuri" ? "../assets/yuri-sticker-distorted-excited.png" : ""
            distorted: modelData === "yuri" && row.failCount >= 2
            isMonika: modelData === "monika"
            xMin: row.sideReserve + index * bandW + 10
            xMax: Math.max(xMin + 10, row.sideReserve + (index + 1) * bandW - width - 10)
            driftDuration: 4800 + index * 1100
            frozen: row.justMonika
            centerTo: (row.width - width) / 2
            // Sayori leaves after the 1st failure; the easter egg keeps only Monika
            gone: (modelData === "sayori" && row.failCount >= 1)
                  || (row.justMonika && modelData !== "monika")
        }
    }

    // Now and then a random character hops by itself — the screen lives without a mouse
    Timer {
        id: idleHops

        interval: 6000
        repeat: true
        running: !row.justMonika
        onTriggered: {
            interval = 6000 + Math.floor(Math.random() * 9000)
            var it = rep.itemAt(Math.floor(Math.random() * rep.count))
            if (it && !it.gone)
                it.hop(true)
        }
    }
}
