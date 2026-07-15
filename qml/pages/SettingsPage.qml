import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    Rectangle { anchors.fill: parent; color: "#e8e6f0"; z: -1 }
    objectName: "settingsPage"
    allowedOrientations: Orientation.All

    Item {
        width: parent.width
        height: 20
        z: 10
    }

    SilicaFlickable {
        id: flickable
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 120
        }
        contentHeight: contentColumn.height + Theme.paddingLarge

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium

            // Кастомный переключатель вместо TextSwitch
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Label {
                    text: qsTr("Автоматическая расшифровка")
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeMedium
                    width: parent.width - 80
                    wrapMode: Text.WordWrap
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 60
                    height: 30
                    radius: 15
                    color: autoTranscribe.checked ? "#e94560" : "#cccccc"
                    anchors.verticalCenter: parent.verticalCenter

                    QtObject {
                        id: autoTranscribe
                        property bool checked: true
                    }

                    Rectangle {
                        x: autoTranscribe.checked ? parent.width - 26 : 4
                        y: 3
                        width: 24
                        height: 24
                        radius: 12
                        color: "white"
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: autoTranscribe.checked = !autoTranscribe.checked
                    }
                }
            }

            // Переключатель сохранения аудио
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Label {
                    text: qsTr("Сохранять аудиозаписи")
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeMedium
                    width: parent.width - 80
                    wrapMode: Text.WordWrap
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 60
                    height: 30
                    radius: 15
                    color: audioRecorder.saveAudio ? "#e94560" : "#cccccc"
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        x: audioRecorder.saveAudio ? parent.width - 26 : 4
                        y: 3
                        width: 24
                        height: 24
                        radius: 12
                        color: "white"
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: audioRecorder.saveAudio = !audioRecorder.saveAudio
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Распознавание")
                color: "#000000"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                height: Theme.itemSizeSmall
                verticalAlignment: Text.AlignVCenter
            }

            // Кастомный селектор — клик переключает модели по кругу
            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    text: qsTr("Модель")
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeSmall
                }

                Rectangle {
                    id: modelSelector
                    width: parent.width
                    height: 50
                    radius: 8
                    color: Qt.rgba(0.9, 0.88, 0.94, 0.5)
                    border.width: 1
                    border.color: "#d4cfe8"

                    property int currentIndex: 0

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.paddingMedium

                        Label {
                            text: modelSelector.currentIndex === 0 ? qsTr("Whisper tiny (быстрая)") : qsTr("Whisper small (точная)")
                            color: "#000000"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: "↻"
                            color: "#e94560"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelSelector.currentIndex === 0) {
                                modelSelector.currentIndex = 1
                                transcriptWorker.modelPath = "/usr/share/ru.alx114.SpeechNotesExp/models/ggml-small-q8_0.bin"
                                modelInfo.text = qsTr("244M параметров, высокая точность")
                            } else {
                                modelSelector.currentIndex = 0
                                transcriptWorker.modelPath = "/usr/share/ru.alx114.SpeechNotesExp/models/ggml-tiny-q8_0.bin"
                                modelInfo.text = qsTr("39M параметров, быстрая работа")
                            }
                        }
                    }
                }
            }

            Label {
                id: modelInfo
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("39M параметров, быстрая работа")
                color: "#333333"
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("О приложении")
                color: "#000000"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                height: Theme.itemSizeSmall
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: 240
                color: Theme.rgba("#333333", 0.08)
                radius: 16

                Column {
                    anchors {
                        fill: parent
                        margins: Theme.paddingLarge
                    }
                    spacing: Theme.paddingMedium

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "../icons/86x86/ru.alx114.SpeechNotesExp.png"
                        width: 86
                        height: 86
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("SpeechNotesExp")
                        font.pixelSize: Theme.fontSizeLarge
                        color: "#e94560"
                        font.bold: true
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Версия 1.0.0")
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        text: qsTr("Голосовые заметки с офлайн-расшифровкой")
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Разработчик: ru.alx114")
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }

            Item {
                height: Theme.paddingLarge
                width: parent.width
            }
        }
    }

    VerticalScrollDecorator {
        flickable: flickable
    }
}