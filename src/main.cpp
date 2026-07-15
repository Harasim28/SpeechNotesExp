#include <auroraapp.h>
#include <QtQuick>
#include <QQmlEngine>
#include "audiorecorder.h"
#include "transcriptworker.h"
#include "notemodel.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));

    application->setOrganizationName(QStringLiteral("ru.alx114"));
    application->setApplicationName(QStringLiteral("SpeechNotesExp"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());

    AudioRecorder audioRecorder;
    NoteModel noteModel;
    TranscriptWorker transcriptWorker;

    view->rootContext()->setContextProperty(QStringLiteral("audioRecorder"), &audioRecorder);
    view->rootContext()->setContextProperty(QStringLiteral("noteModel"), &noteModel);
    view->rootContext()->setContextProperty(QStringLiteral("transcriptWorker"), &transcriptWorker);

    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/SpeechNotes.qml")));
    view->show();

    return application->exec();
}
