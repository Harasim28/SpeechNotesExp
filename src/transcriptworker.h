#ifndef TRANSCRIPTWORKER_H
#define TRANSCRIPTWORKER_H

#include <QObject>
#include <QString>
#include <QElapsedTimer>
#include <QVector>
#include <QFuture>
#include <QtConcurrent>

struct whisper_context;

class TranscriptWorker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString modelPath READ modelPath WRITE setModelPath NOTIFY modelPathChanged)

public:
    explicit TranscriptWorker(QObject *parent = nullptr);
    ~TranscriptWorker();

    QString modelPath() const { return m_modelPath; }
    void setModelPath(const QString &path);

public slots:
    void process(const QString &audioPath);

signals:
    void finished(const QString &text, int elapsedMs);
    void progress(int percent);
    void error(const QString &message);
    void modelPathChanged();

private:
    QString m_audioPath;
    QString m_modelPath;
    whisper_context *m_wctx;
    QFuture<void> m_future;

    bool loadModel();
    QVector<float> loadWav(const QString &path);
    void doTranscription();
};

#endif // TRANSCRIPTWORKER_H