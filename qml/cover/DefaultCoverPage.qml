import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    objectName: "coverBackground"

    Image {
        anchors.centerIn: parent
        source: "../icons/172x172/ru.alx114.SpeechNotesExp.png"
        width: 86
        height: 86
        fillMode: Image.PreserveAspectFit
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 60
        text: qsTr("SpeechNotes")
        color: "#000000"
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 100
        text: qsTr("Голосовые заметки")
        color: "#333333"
        font.pixelSize: Theme.fontSizeSmall
    }

    cover: CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-m-mic"
            onTriggered: {
                console.log("Cover quick record")
                audioRecorder.startRecording()
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-m-note"
            onTriggered: {
                console.log("Cover open notes")
                mainWindow.activate()
                pageStack.replaceAbove(null, Qt.resolvedUrl("pages/NotesPage.qml"))
            }
        }
    }
}
