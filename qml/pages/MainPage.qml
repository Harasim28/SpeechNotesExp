import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
    Rectangle { anchors.fill: parent; color: "#e8e6f0"; z: -1 }
    objectName: "mainPage"
    allowedOrientations: Orientation.All

    property int recordSeconds: 0
    property string recordTime: "00:00"
    property bool showSavedNotification: false
    property bool showTranscriptionProgress: false
    property int transcriptionProgress: 0
    property bool isProcessing: false
    property string currentAudioPath: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge
        anchors.bottomMargin: 120

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingLarge

            // Индикатор уровня сигнала
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: 100
                radius: 16
                color: audioRecorder.isRecording ? Qt.rgba(0.91, 0.27, 0.37, 0.12) : Qt.rgba(0.91, 0.9, 0.94, 0.06)
                x: Theme.horizontalPageMargin
                border.width: 1
                border.color: audioRecorder.isRecording ? Qt.rgba(0.91, 0.27, 0.37, 0.3) : Qt.rgba(0.91, 0.9, 0.94, 0.15)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        id: barRepeater
                        model: 25

                        Rectangle {
                            id: bar
                            width: 6
                            height: 10
                            radius: 3
                            color: audioRecorder.isRecording ? "#e94560" : "#333333"
                            Behavior on height {
                                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // Таймер
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recordTime
                font.pixelSize: Theme.fontSizeExtraLarge
                color: audioRecorder.isRecording ? "#e94560" : "#000000"
            }

            // Прогресс транскрибации
            Rectangle {
                id: progressCard
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: 70
                radius: 12
                color: Qt.rgba(0.91, 0.27, 0.37, 0.12)
                x: Theme.horizontalPageMargin
                opacity: showTranscriptionProgress ? 1.0 : 0.0
                visible: opacity > 0.001

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: 6

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Расшифровка... %1%").arg(transcriptionProgress)
                        color: "#e94560"
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    ProgressBar {
                        width: parent.width
                        value: transcriptionProgress / 100.0
                    }
                }
            }

            // Основная кнопка записи с пульсацией
            Item {
                width: parent.width
                height: 130

                Rectangle {
                    id: recordPulse
                    anchors.centerIn: recordButton
                    width: 100
                    height: 100
                    radius: 50
                    color: audioRecorder.isRecording ? Qt.rgba(0.91, 0.27, 0.37, 0.25) : Qt.rgba(0.91, 0.27, 0.37, 0.1)
                    visible: audioRecorder.isRecording

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: audioRecorder.isRecording
                        NumberAnimation { to: 1.25; duration: 800; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    }
                }

                Rectangle {
                    id: recordButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 100
                    radius: audioRecorder.isRecording ? 16 : 50
                    color: audioRecorder.isRecording ? "#e94560" : "#e94560"
                    Behavior on radius {
                        NumberAnimation { duration: 200 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: audioRecorder.isRecording ? "◼" : "●"
                        color: "white"
                        font.pixelSize: 48
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (audioRecorder.isRecording) {
                                audioRecorder.stopRecording()
                            } else {
                                recordSeconds = 0
                                recordTime = "00:00"
                                audioRecorder.startRecording()
                            }
                        }
                    }
                }
            }

            // Кнопки управления
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
                visible: audioRecorder.isRecording || audioRecorder.isPaused

                // Пауза / продолжить
                Rectangle {
                    width: 70
                    height: 70
                    radius: 35
                    color: audioRecorder.isPaused ? "#e94560" : Qt.rgba(0.91, 0.9, 0.94, 0.15)

                    Label {
                        anchors.centerIn: parent
                        text: audioRecorder.isPaused ? "▶" : "⏸"
                        color: "white"
                        font.pixelSize: 30
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (audioRecorder.isPaused) {
                                audioRecorder.resumeRecording()
                            } else {
                                audioRecorder.pauseRecording()
                            }
                        }
                    }
                }

                // Отмена
                Rectangle {
                    width: 70
                    height: 70
                    radius: 35
                    color: Qt.rgba(0.91, 0.27, 0.37, 0.7)

                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "white"
                        font.pixelSize: 30
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: audioRecorder.cancelRecording()
                    }
                }
            }

            // Кнопка выбора файла для импорта/расшифровки
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: 70
                radius: 12
                color: Qt.rgba(0.91, 0.27, 0.37, 0.1)
                x: Theme.horizontalPageMargin

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(filePickerComponent)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.paddingMedium

                    Label {
                        text: "⇪"
                        color: "#e94560"
                        font.pixelSize: Theme.fontSizeLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: qsTr("Импортировать аудиофайл")
                        color: "#e94560"
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Уведомление "Запись сохранена"
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: 60
                radius: 8
                color: Qt.rgba(0.91, 0.27, 0.37, 0.15)
                x: Theme.horizontalPageMargin
                opacity: showSavedNotification ? 1.0 : 0.0
                visible: opacity > 0.001

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                Label {
                    anchors.centerIn: parent
                    text: qsTr("Запись сохранена")
                    color: "#e94560"
                    font.pixelSize: Theme.fontSizeMedium
                }
            }
        }
    }

    // File picker для импорта аудио
    Component {
        id: filePickerComponent
        FilePickerPage {
            title: qsTr("Выберите аудиофайл")
            nameFilters: ["*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a"]
            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties && selectedContentProperties.filePath) {
                    var path = selectedContentProperties.filePath
                    // Проверяем что это файл (имеет расширение), а не папка
                    var lower = path.toString().toLowerCase()
                    if (lower.indexOf(".wav") >= 0 || lower.indexOf(".mp3") >= 0 ||
                        lower.indexOf(".ogg") >= 0 || lower.indexOf(".flac") >= 0 ||
                        lower.indexOf(".m4a") >= 0) {
                        // Находим MainPage в стеке и возвращаемся к ней
                        var mainPage = pageStack.find(function(page) {
                            return page.objectName === "mainPage"
                        })
                        if (mainPage) {
                            pageStack.pop(mainPage)
                        } else {
                            pageStack.pop()
                        }
                        importAudio(path)
                    }
                }
            }
        }
    }

    // Таймер для обновления полосок
    Timer {
        id: barsTimer
        interval: 100
        running: audioRecorder.isRecording
        repeat: true
        onTriggered: {
            for (var i = 0; i < barRepeater.count; i++) {
                var item = barRepeater.itemAt(i)
                if (item) {
                    if (audioRecorder.isRecording && !audioRecorder.isPaused) {
                        item.height = 10 + Math.random() * 70
                    } else {
                        item.height = 10
                    }
                }
            }
        }
    }

    // Таймер для сброса уведомления
    Timer {
        id: notificationTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: showSavedNotification = false
    }

    // Таймер для отсчёта времени
    Timer {
        id: timer
        interval: 1000
        running: audioRecorder.isRecording && !audioRecorder.isPaused
        repeat: true

        onTriggered: {
            recordSeconds += 1
            var minutes = Math.floor(recordSeconds / 60)
            var seconds = recordSeconds % 60
            recordTime = (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds
        }
    }

    Connections {
        target: audioRecorder
        onRecordingStateChanged: {
            if (!audioRecorder.isRecording) {
                recordSeconds = 0
                recordTime = "00:00"
            }
        }
        onAudioSaved: {
            showSavedNotification = true
            notificationTimer.start()
            startTranscription(path)
        }
    }

    Component.onCompleted: {
    }

    Connections {
        target: transcriptWorker
        onProgress: {
            transcriptionProgress = percent
        }
        onFinished: {
            var dur = 0
            if (currentAudioPath.length > 0) {
                dur = audioRecorder.getAudioDurationSec(currentAudioPath)
            }
            if (dur < 1) {
                dur = Math.max(1, Math.round(audioRecorder.duration / 1000))
            }
            noteModel.addNote("", text, "", dur)
            showTranscriptionProgress = false
            isProcessing = false
        }
        onError: {
            showTranscriptionProgress = false
            isProcessing = false
        }
    }

    function startTranscription(audioPath) {
        showTranscriptionProgress = true
        transcriptionProgress = 0
        isProcessing = true
        currentAudioPath = audioPath
        transcriptWorker.process(audioPath)
    }

    function importAudio(filePath) {
        isProcessing = true
        showTranscriptionProgress = true
        transcriptionProgress = 0
        // Временное копирование в AppData и запуск расшифровки
        var targetPath = audioRecorder.importAudioFile(filePath)
        if (targetPath && targetPath.length > 0) {
            startTranscription(targetPath)
        } else {
            startTranscription(filePath)
        }
    }
}
