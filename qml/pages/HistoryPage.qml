import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    Rectangle { anchors.fill: parent; color: "#e8e6f0"; z: -1 }
    objectName: "historyPage"
    allowedOrientations: Orientation.All

    PageHeader {
        objectName: "historyHeader"
        title: qsTr("История записей")
    }

    SilicaListView {
        id: historyList
        anchors.fill: parent
        clip: true
        spacing: Theme.paddingMedium
        model: noteModel

        delegate: ListItem {
            id: historyItem
            width: parent.width
            contentHeight: historyColumn.height + 2 * Theme.paddingMedium

            Rectangle {
                anchors.fill: parent
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.rgba("#333333", 0.06)
                radius: 12
            }

            Column {
                id: historyColumn
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
                    spacing: Theme.paddingMedium

                    Label {
                        text: createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy") : ""
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width * 0.4
                    }

                    Label {
                        text: createdAt ? Qt.formatDateTime(createdAt, "hh:mm") : ""
                        color: "#333333"
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        text: duration > 0 ? formatDuration(duration) : ""
                        color: "#e94560"
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                        anchors.right: parent.right
                    }
                }

                Label {
                    text: title
                    color: "#000000"
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Label {
                    text: noteText
                    color: "#333333"
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotesEditorPage.qml"), {
                    "noteTitle": title,
                    "noteText": noteText,
                    "noteDate": createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy hh:mm") : "",
                    "noteDuration": duration > 0 ? formatDuration(duration) : ""
                })
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Открыть")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("NotesEditorPage.qml"), {
                            "noteTitle": title,
                            "noteText": noteText,
                            "noteDate": createdAt ? Qt.formatDateTime(createdAt, "dd.MM.yyyy hh:mm") : "",
                            "noteDuration": duration > 0 ? formatDuration(duration) : ""
                        })
                    }
                }
                MenuItem {
                    text: qsTr("Удалить")
                    onClicked: historyItem.remorseDelete(function() {
                        noteModel.removeNote(index)
                    })
                }
            }
        }

        ViewPlaceholder {
            enabled: historyList.count === 0
            text: qsTr("Нет записей")
            hintText: qsTr("Запишите или импортируйте аудио")
        }
    }

    function formatDuration(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}
