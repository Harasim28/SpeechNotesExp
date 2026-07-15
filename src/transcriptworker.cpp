#include "transcriptworker.h"

#include <QDebug>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QTextStream>
#include <QDateTime>
#include <QElapsedTimer>
#include <cmath>

extern "C" {
#include "whisper.h"
}

static void logToFile(const QString &msg)
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    QFile f(dir + "/vovan_debug.log");
    if (f.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream s(&f);
        s << QDateTime::currentDateTime().toString("hh:mm:ss.zzz") << " " << msg << "\n";
    }
}

TranscriptWorker::TranscriptWorker(QObject *parent) : QObject(parent)
    , m_wctx(nullptr)
{
    m_modelPath = "/usr/share/ru.alx114.SpeechNotesExp/models/ggml-tiny-q8_0.bin";
    logToFile("TranscriptWorker created, default model: " + m_modelPath);
}

TranscriptWorker::~TranscriptWorker()
{
    logToFile("TranscriptWorker destroyed");
    m_future.waitForFinished();
    if (m_wctx) {
        whisper_free(m_wctx);
        m_wctx = nullptr;
    }
}

void TranscriptWorker::setModelPath(const QString &path)
{
    if (m_modelPath != path) {
        m_modelPath = path;
        // Need to reload model if already loaded
        if (m_wctx) {
            whisper_free(m_wctx);
            m_wctx = nullptr;
        }
        logToFile("Model path changed to: " + path);
        emit modelPathChanged();
    }
}

bool TranscriptWorker::loadModel()
{
    if (m_wctx)
        return true;

    QString modelPath = m_modelPath;
    if (modelPath.isEmpty())
        modelPath = "/usr/share/ru.alx114.SpeechNotesExp/models/ggml-tiny-q8_0.bin";

    if (!QFile::exists(modelPath)) {
        logToFile("Model not found: " + modelPath);
        return false;
    }

    logToFile("Loading model: " + modelPath);
    whisper_context_params cparams = whisper_context_default_params();
    m_wctx = whisper_init_from_file_with_params(modelPath.toUtf8().constData(), cparams);
    if (!m_wctx) {
        logToFile("Failed to load model");
        return false;
    }
    logToFile("Model loaded OK");
    return true;
}

QVector<float> TranscriptWorker::loadWav(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        logToFile("Cannot open: " + path);
        return {};
    }
    QByteArray data = file.readAll();
    if (data.size() < 44) return {};

    const uchar *raw = (const uchar *)data.constData();
    if (raw[0]!='R'||raw[1]!='I'||raw[2]!='F'||raw[3]!='F') return {};

    int channels = raw[22] | (raw[23]<<8);
    int sampleRate = raw[24]|(raw[25]<<8)|(raw[26]<<16)|(raw[27]<<24);
    int bps = raw[34]|(raw[35]<<8);
    int dataOff = 44;
    for (int i=12; i<data.size()-8; ++i) {
        if (raw[i]=='d'&&raw[i+1]=='a'&&raw[i+2]=='t'&&raw[i+3]=='a') {
            dataOff = i+8; break;
        }
    }

    if (bps != 16) return {};

    int n = (data.size()-dataOff)/(channels*2);
    QVector<float> mono;
    mono.reserve(n);
    const qint16 *s = (const qint16*)(data.constData()+dataOff);
    for (int i=0; i<n; ++i) {
        float sum=0;
        for(int c=0;c<channels;++c) sum += s[i*channels+c]/32768.0f;
        mono.append(sum/channels);
    }

    if (sampleRate != 16000) {
        int outN = (n * 16000) / sampleRate;
        QVector<float> resampled;
        resampled.reserve(outN);
        for (int i=0; i<outN; ++i) {
            double pos = (double)i * sampleRate / 16000;
            int idx = (int)pos;
            double frac = pos - idx;
            float v0 = (idx >= 0 && idx < n) ? mono[idx] : 0.0f;
            float v1 = (idx+1 >= 0 && idx+1 < n) ? mono[idx+1] : 0.0f;
            resampled.append(v0*(1.0f-(float)frac) + v1*(float)frac);
        }
        mono = resampled;
    }

    logToFile(QString("Loaded %1 samples from %2").arg(mono.size()).arg(path));
    return mono;
}

void TranscriptWorker::doTranscription()
{
    QElapsedTimer timer;
    timer.start();

    logToFile("doTranscription() started in thread pool");

    if (!loadModel()) {
        emit error("Model load failed");
        return;
    }

    emit progress(15);

    QVector<float> samples = loadWav(m_audioPath);
    if (samples.isEmpty()) {
        emit error("Failed to load audio");
        return;
    }

    emit progress(25);

    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.translate = false;
    params.language = "ru";
    params.n_threads = 4;
    params.print_progress = false;
    params.print_special = false;
    params.print_realtime = false;
    params.print_timestamps = false;

    logToFile(QString("Running whisper_full on %1 samples").arg(samples.size()));

    int ret = whisper_full(m_wctx, params, samples.constData(), samples.size());
    logToFile(QString("whisper_full returned: %1").arg(ret));

    if (ret != 0) {
        emit error("Whisper inference failed");
        return;
    }

    emit progress(90);

    int nSeg = whisper_full_n_segments(m_wctx);
    QString result;
    for (int i=0; i<nSeg; ++i) {
        const char *text = whisper_full_get_segment_text(m_wctx, i);
        if (text) {
            result += QString::fromUtf8(text) + " ";
        }
    }

    int elapsed = timer.elapsed();
    logToFile(QString("RESULT: %1 (took %2 ms)").arg(result.trimmed()).arg(elapsed));
    emit progress(100);
    emit finished(result.trimmed(), elapsed);
}

void TranscriptWorker::process(const QString &audioPath)
{
    logToFile("process() called: " + audioPath);
    m_audioPath = audioPath;
    emit progress(0);

    // Run in thread pool — non-blocking
    m_future = QtConcurrent::run(this, &TranscriptWorker::doTranscription);
}