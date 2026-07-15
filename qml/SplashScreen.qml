import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: splashRoot
    anchors.fill: parent
    signal finished()

    Rectangle {
        anchors.fill: parent
        color: Theme.rgba("#000000", 0.12)

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba("#e94560", 0.06)
            opacity: 0.6
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.paddingLarge

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../icons/128x128/ru.alx114.SpeechNotesExp.png"
                width: 128
                height: 128
                fillMode: Image.PreserveAspectFit
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("SpeechNotesExp")
                color: "#e94560"
                font.pixelSize: Theme.fontSizeExtraLarge
                font.bold: true
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Голосовые заметки")
                color: "#333333"
                font.pixelSize: Theme.fontSizeMedium
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
                size: BusyIndicatorSize.Medium
            }
        }
    }

    Timer {
        running: true
        repeat: false
        interval: 2000
        onTriggered: {
            splashRoot.finished()
        }
    }
}