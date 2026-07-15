import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    Rectangle { anchors.fill: parent; color: "#e8e6f0"; z: -1 }
    objectName: "noteEditorPage"
    allowedOrientations: Orientation.All

    property int noteIndex: -1
    property string noteTitle: ""
    property string noteText: ""
    property string noteDate: ""
    property string noteDuration: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: 50
                radius: 8
                color: Qt.rgba(0.9, 0.88, 0.94, 0.5)
                border.width: 1
                border.color: "#d4cfe8"
                visible: noteDate.length > 0 || noteDuration.length > 0

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.paddingMedium

                    Label {
                        text: noteDate
                        color: "#000000"
                        font.pixelSize: Theme.fontSizeSmall
                        visible: noteDate.length > 0
                    }

                    Label {
                        text: noteDuration
                        color: "#e94560"
                        font.pixelSize: Theme.fontSizeSmall
                        visible: noteDuration.length > 0
                    }
                }
            }

            // Заголовок (редактируемый)
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: 60
                radius: 8
                color: Qt.rgba(0.9, 0.88, 0.94, 0.5)
                border.width: 1
                border.color: "#d4cfe8"

                TextInput {
                    id: titleInput
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: noteTitle
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    clip: true
                }
            }

            // Текст заметки (редактируемый)
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: Math.max(200, parent.height * 0.4)
                radius: 8
                color: Qt.rgba(0.9, 0.88, 0.94, 0.5)
                border.width: 1
                border.color: "#d4cfe8"

                TextEdit {
                    id: textInput
                    anchors {
                        fill: parent
                        margins: Theme.paddingMedium
                    }
                    text: noteText
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                    clip: true
                }
            }

            // Кнопка сохранения
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: 50
                radius: 25
                color: "#e94560"

                Label {
                    anchors.centerIn: parent
                    text: noteIndex >= 0 ? qsTr("Сохранить") : qsTr("Добавить")
                    color: "white"
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (noteIndex >= 0) {
                            noteModel.updateNote(noteIndex, titleInput.text, textInput.text)
                        } else {
                            noteModel.addNote(titleInput.text, textInput.text, "", 0)
                        }
                        pageStack.pop()
                    }
                }
            }
        }
    }
}