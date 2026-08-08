import QtQuick

// Easter egg: after three wrong passwords little "Just Monika" windows appear
// across the screen one after another. Each one closes on click
Item {
    id: popups

    property bool active: false
    property int total: 7

    onActiveChanged: {
        cards.clear()
        if (active) {
            spawnTimer.spawned = 0
            spawnTimer.restart()
        } else {
            spawnTimer.stop()
        }
    }

    property int nextId: 0

    ListModel {
        id: cards
    }

    // Removal by unique id — model indices shift as windows close
    function closeCid(cid) {
        for (var i = 0; i < cards.count; i++) {
            if (cards.get(i).cid === cid) {
                cards.remove(i)
                break
            }
        }
    }

    Timer {
        id: spawnTimer

        property int spawned: 0

        interval: 350
        repeat: true
        onTriggered: {
            if (spawned >= popups.total) {
                stop()
                return
            }
            // Stay clear of the bottom strip with the sprites and the buttons
            cards.append({
                cid: popups.nextId++,
                px: 30 + Math.random() * Math.max(1, popups.width - 260),
                py: 30 + Math.random() * Math.max(1, popups.height - 400)
            })
            spawned++
        }
    }

    Repeater {
        model: cards

        Image {
            id: card

            readonly property int cid: model.cid

            x: px
            y: py
            width: 190
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            source: "../assets/just-monika-ok.png"
            transformOrigin: Item.Center

            // Appears with a slight pop
            scale: 0
            NumberAnimation on scale {
                id: appear

                from: 0
                to: 1
                duration: 260
                easing.type: Easing.OutBack
            }

            // Click to close: the window shrinks back and is removed
            NumberAnimation {
                id: shrink

                target: card
                property: "scale"
                to: 0
                duration: 320
                easing.type: Easing.InBack
                onFinished: popups.closeCid(card.cid)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !shrink.running
                onClicked: {
                    appear.stop()
                    shrink.start()
                }
            }
        }
    }
}
