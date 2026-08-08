import QtQuick
import QtQuick.Shapes

// The DDLC menu background: a grid of dots (odd rows offset by half a step)
// crawling diagonally. Movement integrates velocity per frame (FrameAnimation)
// so it can be brought to a smooth halt and accelerated back the other way just
// as smoothly — which is what the easter-egg mode does
Item {
    id: bg

    clip: true

    // "Just Monika" mode: black background, red dots, reversed movement
    property bool corrupted: false
    // From the 2nd failure the even dot outline breaks into a spiky, ragged contour
    property bool rough: false

    // JPEG artefacts: from the 2nd failure the dot layer renders into a downscaled
    // texture stretched with nearest sampling — the blocks read as compression
    layer.enabled: rough
    layer.smooth: false
    layer.textureSize: Qt.size(Math.max(1, width / 7), Math.max(1, height / 7))

    readonly property int step: parseInt(config.dotSpacing) > 0 ? parseInt(config.dotSpacing) : 165
    readonly property int dotR: parseInt(config.dotRadius) > 0 ? parseInt(config.dotRadius) : 44
    readonly property int scrollMs: parseInt(config.scrollDuration) > 0 ? parseInt(config.scrollDuration) : 14000
    readonly property int cols: Math.ceil(width / step) + 3
    readonly property int rows: Math.ceil(height / step) + 5

    // Base speed (px/s) at vel = 1; vel is the multiplier and the direction sign
    readonly property real baseVel: step * 1000 / scrollMs
    property real vel: 1
    property real pos: 0

    property color dotColorNow: config.dotColor
    Behavior on dotColorNow {
        ColorAnimation {
            duration: 3000
        }
    }

    onCorruptedChanged: {
        dotColorNow = corrupted ? config.corruptDot : config.dotColor
        velAnim.stop()
        if (corrupted)
            velAnim.start()
        else
            vel = 1
    }

    function wrapMod(v, m) {
        return ((v % m) + m) % m;
    }

    // Per-frame offset integrator
    FrameAnimation {
        running: true
        onTriggered: bg.pos += bg.baseVel * bg.vel * frameTime
    }

    // Smoothly: decay the movement to zero first, then accelerate the other way
    SequentialAnimation {
        id: velAnim

        NumberAnimation {
            target: bg
            property: "vel"
            to: 0
            duration: 2600
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: bg
            property: "vel"
            to: -1
            duration: 2600
            easing.type: Easing.InOutSine
        }
    }

    Item {
        id: field

        // x repeats with period step, y with 2·step — the rows are offset
        x: bg.wrapMod(bg.pos, bg.step) - bg.step
        y: bg.wrapMod(bg.pos * 2, bg.step * 2) - bg.step * 2

        Repeater {
            model: bg.cols * bg.rows

            // A dot as a polygon: a smooth circle normally, and under rough the
            // vertices scatter into chaotic spikes
            Shape {
                id: dot

                readonly property int row: Math.floor(index / bg.cols)
                readonly property int col: index % bg.cols
                readonly property int verts: 26

                // Stable random seeds per vertex: radial and angular
                readonly property var seedR: {
                    var a = [];
                    for (var i = 0; i < verts; i++)
                        a.push(Math.random());
                    return a;
                }
                readonly property var seedA: {
                    var a = [];
                    for (var i = 0; i < verts; i++)
                        a.push(Math.random());
                    return a;
                }

                // Spikiness: 0 is a circle, 1 is a ragged contour
                property real spikiness: bg.rough ? 1 : 0
                Behavior on spikiness {
                    NumberAnimation {
                        duration: 1800
                        easing.type: Easing.InOutSine
                    }
                }

                x: col * bg.step + (row % 2 === 1 ? bg.step / 2 : 0) - bg.step
                y: row * bg.step - bg.step * 2
                width: bg.dotR * 2
                height: bg.dotR * 2
                // GeometryRenderer over CurveRenderer: the contour is straight
                // segments and needs no curves — many times cheaper across ~100
                // shapes, and it removes the background stutter
                preferredRendererType: Shape.GeometryRenderer
                antialiasing: true

                function buildPath() {
                    var pts = [];
                    var c = bg.dotR;
                    var stepA = 2 * Math.PI / verts;
                    for (var i = 0; i <= verts; i++) {
                        var k = i % verts;
                        // angular jitter per vertex — the contour stops being symmetric
                        var ang = stepA * k + (seedA[k] - 0.5) * stepA * 0.9 * spikiness;
                        // mostly small dents, occasionally a long spike outward
                        var s = seedR[k];
                        var spike = (s > 0.66) ? (0.45 + (s - 0.66) * 2.6) : (-0.22 * s);
                        var rr = bg.dotR * (1 + spike * spikiness);
                        pts.push(Qt.point(c + rr * Math.cos(ang), c + rr * Math.sin(ang)));
                    }
                    return pts;
                }

                ShapePath {
                    fillColor: bg.dotColorNow
                    strokeColor: bg.dotColorNow
                    strokeWidth: 1

                    PathPolyline {
                        // recomputed when spikiness changes (circle→spike morph)
                        path: dot.buildPath()
                    }
                }
            }
        }
    }
}
