#ifndef AUDIORECORDER_H
#define AUDIORECORDER_H

#include <QObject>
#include <QString>
#include <QElapsedTimer>
#include <QTimer>

QT_BEGIN_NAMESPACE
class QAudioInput;
class QFile;
QT_END_NAMESPACE

class AudioRecorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY recordingStateChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY pausedStateChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString audioPath READ audioPath NOTIFY audioSaved)
    Q_PROPERTY(bool saveAudio READ saveAudio WRITE setSaveAudio NOTIFY saveAudioChanged)

public:
    explicit AudioRecorder(QObject *parent = nullptr);
    ~AudioRecorder();

    bool isRecording() const { return m_isRecording; }
    bool isPaused() const { return m_isPaused; }
    qint64 duration() const { return m_duration; }
    QString audioPath() const { return m_audioPath; }
    bool saveAudio() const { return m_saveAudio; }
    void setSaveAudio(bool save) { if (m_saveAudio != save) { m_saveAudio = save; emit saveAudioChanged(); } }

    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void pauseRecording();
    Q_INVOKABLE void resumeRecording();
    Q_INVOKABLE void cancelRecording();
    Q_INVOKABLE QString importAudioFile(const QString &sourcePath);
    Q_INVOKABLE int getAudioDurationSec(const QString &path);

signals:
    void recordingStateChanged();
    void pausedStateChanged();
    void durationChanged();
    void audioSaved(const QString &path);
    void saveAudioChanged();
    void error(const QString &message);

private slots:
    void updateDuration();

private:
    bool m_isRecording;
    bool m_isPaused;
    bool m_saveAudio;
    qint64 m_duration;
    QString m_audioPath;
    QString m_tempPath;
    QAudioInput *m_audioInput;
    QFile *m_outputFile;
    QElapsedTimer m_elapsedTimer;
    QTimer *m_durationTimer;

    bool openWavFile(const QString &filePath, int sampleRate, int channels, int bitsPerSample);
    void finalizeWavFile();
    bool convertAudioToWav16k(const QString &sourcePath, const QString &targetPath);
};

#endif // AUDIORECORDER_H
