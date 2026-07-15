import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    objectName: "applicationWindow"
    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    allowedOrientations: defaultAllowedOrientations
    cover: Qt.resolvedUrl("cover/DefaultCoverPage.qml")

    property int currentTab: 1
    property bool isChanging: false
    property bool splashVisible: true

    // Сплэш-скрин
    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        z: 1000
        opacity: splashVisible ? 1.0 : 0.0
        visible: opacity > 0.001
        onFinished: {
            splashVisible = false
        }
        Behavior on opacity {
            NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    // Чёрный оверлей для crossfade (поверх всего, под таббаром)
    Rectangle {
        id: fadeOverlay
        anchors.fill: parent
        color: "#e8e6f0"
        opacity: 0.0
        visible: opacity > 0.01
        z: 500

        Behavior on opacity {
            NumberAnimation { id: fadeBehavior; duration: 250; easing.type: Easing.InOutQuad }
        }
    }

    // Нижняя панель
    Rectangle {
        id: tabBar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 120
        color: Theme.rgba("#333333", 0.08)
        z: 600

        Row {
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            spacing: (width - 3 * 84) / 2

            TabButton {
                id: tabNotes
                iconName: "note"
                label: qsTr("Заметки")
                isActive: currentTab === 0
                onClicked: switchToTab(0)
            }

            TabButton {
                id: tabHome
                iconName: "microphone"
                label: qsTr("Запись")
                isActive: currentTab === 1
                onClicked: switchToTab(1)
            }

            TabButton {
                id: tabSettings
                iconName: "settings"
                label: qsTr("Настройки")
                isActive: currentTab === 2
                onClicked: switchToTab(2)
            }
        }
    }

    Timer {
        id: resetTimer
        interval: 600
        running: false
        repeat: false
        onTriggered: isChanging = false
    }

    // Crossfade: затемнение -> смена страницы -> проявление
    function switchToTab(newTab) {
        if (currentTab === newTab || isChanging)
            return
        isChanging = true

        var pageUrl = ""
        if (newTab === 0)
            pageUrl = Qt.resolvedUrl("pages/NotesPage.qml")
        else if (newTab === 1)
            pageUrl = Qt.resolvedUrl("pages/MainPage.qml")
        else if (newTab === 2)
            pageUrl = Qt.resolvedUrl("pages/SettingsPage.qml")

        // Шаг 1: затемнить экран
        fadeOverlay.opacity = 1.0

        // Шаг 2: через 250мс сменить страницу (когда экран чёрный)
        swapTimer.pageUrl = pageUrl
        swapTimer.start()

        currentTab = newTab
        resetTimer.start()
    }

    Timer {
        id: swapTimer
        interval: 260
        repeat: false
        property string pageUrl: ""
        onTriggered: {
            // Сменить страницу без анимации (экран уже чёрный)
            pageStack.replaceAbove(null, pageUrl, {}, PageStackAction.Immediate)
            // Шаг 3: проявить экран
            fadeOverlay.opacity = 0.0
        }
    }

    Component.onCompleted: {
        console.log("SpeechNotes ApplicationWindow loaded")
    }
}