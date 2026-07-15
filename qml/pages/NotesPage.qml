import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    Rectangle { anchors.fill: parent; color: "#e8e6f0"; z: -1 }
    objectName: "notesPage"
    allowedOrientations: Orientation.All

    property string searchText: ""
    property int sortMode: 0

    Column {
        id: topControls
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: Theme.paddingLarge
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
        spacing: Theme.paddingMedium

        TextField {
            id: searchField
            width: parent.width
            placeholderText: qsTr("Поиск по заметкам")
            text: searchText
            color: "#000000"
            placeholderColor: "#333333"
            backgroundStyle: TextField.RoundedBackground
            onTextChanged: searchText = text
        }

        Rectangle {
            width: parent.width
            height: 48
            color: Qt.rgba(0.9, 0.88, 0.94, 0.5)
            radius: 12

            Label {
                anchors.centerIn: parent
                text: sortMode === 0 ? qsTr("Сортировка: Новые") : sortMode === 1 ? qsTr("Сортировка: Старые") : qsTr("Сортировка: По алфавиту")
                color: "#000000"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
            }

            Label {
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                text: "↻"
                color: "#e94560"
                font.pixelSize: Theme.fontSizeMedium
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    sortMode = (sortMode + 1) % 3
                    noteModel.sortNotes(sortMode)
                    console.log("🔃 Sort mode changed to:", sortMode)
                }
            }
        }
    }

    Item {
        width: parent.width
        height: 20
        z: 10
    }

    SilicaListView {
        id: notesListView
        anchors {
            top: topControls.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: Theme.paddingMedium
        }
        clip: true
        spacing: Theme.paddingMedium

        model: noteModel

        delegate: ListItem {
            id: listItem
            width: parent.width
            contentHeight: visible ? contentColumn.height + 2 * Theme.paddingMedium : 0
            visible: searchText.length === 0 || title.toLowerCase().indexOf(searchText.toLowerCase()) >= 0 || model.text.toLowerCase().indexOf(searchText.toLowerCase()) >= 0

            Rectangle {
                anchors.fill: parent
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.rgba("#333333", 0.06)
                radius: 12
            }

            Label {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                }
                text: "★"
                color: pinned ? "#e94560" : "#cccccc"
                font.pixelSize: Theme.fontSizeLarge
                z: 5

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        noteModel.togglePin(index)
                        console.log("⭐ Pin toggled for note:", title)
                    }
                }
            }

            Column {
                id: contentColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                    rightMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                }
                spacing: Theme.paddingSmall

                Row {
                    width: parent.width

                    Label {
                        text: title
                        color: "#000000"
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        width: parent.width - 80
                        elide: Text.ElideRight
                    }

                    Label {
                        text: duration > 0 ? formatDuration(duration) : ""
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                        width: 70
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Label {
                    width: parent.width
                    text: model.text
                    color: "#333333"
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy hh:mm") : ""
                    color: "#333333"
                    font.pixelSize: Theme.fontSizeTiny
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Открыть")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("NotesEditorPage.qml"), {
                            "noteIndex": index,
                            "noteTitle": title,
                            "noteText": model.text,
                            "noteDate": createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy hh:mm") : "",
                            "noteDuration": duration > 0 ? formatDuration(duration) : ""
                        })
                    }
                }
                MenuItem {
                    text: qsTr("Удалить")
                    onClicked: listItem.remorseDelete(function() {
                        noteModel.removeNote(index)
                    })
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotesEditorPage.qml"), {
                    "noteIndex": index,
                    "noteTitle": title,
                    "noteText": model.text,
                    "noteDate": createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy hh:mm") : "",
                    "noteDuration": duration > 0 ? formatDuration(duration) : ""
                })
            }
        }

        // Кастомный placeholder вместо ViewPlaceholder (для контроля цвета)
        Column {
            anchors.centerIn: parent
            visible: notesListView.count === 0
            spacing: Theme.paddingMedium

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Нет заметок")
                color: "#000000"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Запишите голосовую заметку на вкладке Запись")
                color: "#333333"
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width - 2 * Theme.paddingLarge
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            bottom: parent.bottom
            bottomMargin: 140
            leftMargin: Theme.paddingLarge
        }
        width: 70
        height: 70
        radius: 35
        color: "#e94560"
        z: 10

        Label {
            anchors.centerIn: parent
            text: "+"
            color: "white"
            font.pixelSize: 40
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotesEditorPage.qml"), {
                    "noteTitle": "",
                    "noteText": "",
                    "noteDate": "",
                    "noteDuration": ""
                })
            }
        }
    }

    function formatDuration(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}
