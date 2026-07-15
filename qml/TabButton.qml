import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    property string iconName: "microphone"
    property string label: ""
    property bool isActive: false
    signal clicked()

    width: 84
    height: 100

    Canvas {
        id: iconCanvas
        anchors.horizontalCenter: parent.horizontalCenter
        width: 48
        height: 48
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = isActive ? "#e94560" : "#333333"
            ctx.fillStyle = isActive ? "#e94560" : "#333333"
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            var cx = width / 2
            var cy = height / 2
            if (iconName === "microphone") {
                ctx.beginPath()
                ctx.moveTo(cx - 8, cy - 10)
                ctx.lineTo(cx - 8, cy + 4)
                ctx.quadraticCurveTo(cx - 8, cy + 14, cx, cy + 14)
                ctx.quadraticCurveTo(cx + 8, cy + 14, cx + 8, cy + 4)
                ctx.lineTo(cx + 8, cy - 10)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - 12, cy + 4)
                ctx.quadraticCurveTo(cx - 12, cy + 18, cx, cy + 18)
                ctx.quadraticCurveTo(cx + 12, cy + 18, cx + 12, cy + 4)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, cy + 18)
                ctx.lineTo(cx, cy + 24)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - 8, cy + 24)
                ctx.lineTo(cx + 8, cy + 24)
                ctx.stroke()
            } else if (iconName === "note") {
                ctx.beginPath()
                ctx.rect(cx - 9, cy - 12, 18, 24, 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - 5, cy - 4)
                ctx.lineTo(cx + 5, cy - 4)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - 5, cy + 2)
                ctx.lineTo(cx + 5, cy + 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - 5, cy + 8)
                ctx.lineTo(cx + 2, cy + 8)
                ctx.stroke()
            } else if (iconName === "settings") {
                ctx.beginPath()
                ctx.arc(cx, cy, 8, 0, 2 * Math.PI)
                ctx.stroke()
                for (var i = 0; i < 8; i++) {
                    var a = i * Math.PI / 4
                    var x1 = cx + 10 * Math.cos(a)
                    var y1 = cy + 10 * Math.sin(a)
                    var x2 = cx + 14 * Math.cos(a)
                    var y2 = cy + 14 * Math.sin(a)
                    ctx.beginPath()
                    ctx.moveTo(x1, y1)
                    ctx.lineTo(x2, y2)
                    ctx.stroke()
                }
            } else if (iconName === "history") {
                ctx.beginPath()
                ctx.arc(cx, cy, 12, -Math.PI / 2, 3 * Math.PI / 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, cy - 8)
                ctx.lineTo(cx, cy)
                ctx.lineTo(cx + 8, cy + 4)
                ctx.stroke()
            } else if (iconName === "folder") {
                ctx.beginPath()
                ctx.moveTo(cx - 12, cy - 6)
                ctx.lineTo(cx - 4, cy - 6)
                ctx.lineTo(cx - 2, cy - 10)
                ctx.lineTo(cx + 12, cy - 10)
                ctx.lineTo(cx + 12, cy + 8)
                ctx.lineTo(cx - 12, cy + 8)
                ctx.closePath()
                ctx.stroke()
            }
        }
    }

    Label {
        anchors {
            top: iconCanvas.bottom
            topMargin: Theme.paddingSmall
            horizontalCenter: parent.horizontalCenter
        }
        text: label
        font.pixelSize: Theme.fontSizeTiny
        color: isActive ? "#e94560" : "#333333"
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    onIsActiveChanged: iconCanvas.requestPaint()
}
