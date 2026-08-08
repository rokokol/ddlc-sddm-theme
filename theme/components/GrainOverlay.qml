import QtQuick

// Film grain over the background: a grey noise tile that jitters slightly for a
// "live film" feel. Switched on by the caller from the 1st failure
Item {
    id: grain

    property bool active: false

    clip: true
    opacity: active ? 0.14 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 1600
        }
    }

    Image {
        id: tile

        source: "../assets/noise.png"
        fillMode: Image.Tile
        // Larger than the screen so the jitter never exposes an edge
        x: -40
        y: -40
        width: grain.width + 80
        height: grain.height + 80
    }

    // Grain jitter — the tile is seamless, so the shift repeats invisibly
    Timer {
        interval: 70
        repeat: true
        running: grain.active
        onTriggered: {
            tile.x = -40 - Math.random() * 40
            tile.y = -40 - Math.random() * 40
        }
    }
}
