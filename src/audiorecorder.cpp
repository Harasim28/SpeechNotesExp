#include "audiorecorder.h"
#include <QAudioInput>
#include <QAudioFormat>
#include <QAudioDeviceInfo>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QDebug>
#include <QTimer>
#include <QtEndian>
#include <QDataStream>
#include <QProcess>

namespace {
    const int SAMPLE_RATE = 16000;
    const int CHANNELS = 1;
    const int BITS_PER_SAMPLE = 16;
}

AudioRecorder::AudioRecorder(QObject *parent) : QObject(parent)
    , m_isRecording(false)
    , m_isPaused(false)
    , m_saveAudio(true)
    , m_duration(0)
    , m_audioInput(nullptr)
    , m_outputFile(nullptr)
    , m_durationTimer(new QTimer(this))
{
    m_durationTimer->setInterval(1000);
    m_durationTimer->setSingleShot(false);
    connect(m_durationTimer, &QTimer::timeout, this, &AudioRecorder::updateDuration);
    qDebug() << "AudioRecorder initialized";
}

AudioRecorder::~AudioRecorder()
{
    stopRecording();
}

bool AudioRecorder::openWavFile(const QString &filePath, int sampleRate, int channels, int bitsPerSample)
{
    QFile *file = new QFile(filePath, this);
    if (!file->open(QIODevice::WriteOnly)) {
        emit error(tr("Cannot open audio file for writing: %1").arg(file->errorString()));
        delete file;
        return false;
    }

    m_outputFile = file;
    m_tempPath = filePath;

    // Reserve 44 bytes for WAV header; will be rewritten in finalizeWavFile().
    QByteArray header(44, 0);
    m_outputFile->write(header);
    m_outputFile->flush();

    return true;
}

void AudioRecorder::finalizeWavFile()
{
    if (!m_outputFile)
        return;

    qint64 dataSize = m_outputFile->size() - 44;
    if (dataSize < 0)
        dataSize = 0;

    m_outputFile->seek(0);

    QDataStream stream(m_outputFile);
    stream.setByteOrder(QDataStream::LittleEndian);

    // RIFF
    stream.writeRawData("RIFF", 4);
    stream << qint32(dataSize + 36); // chunk size
    // WAVE
    stream.writeRawData("WAVE", 4);
    // fmt
    stream.writeRawData("fmt ", 4);
    stream << qint32(16);          // subchunk1 size
    stream << qint16(1);           // audio format PCM
    stream << qint16(CHANNELS);
    stream << qint32(SAMPLE_RATE);
    stream << qint32(SAMPLE_RATE * CHANNELS * BITS_PER_SAMPLE / 8); // byte rate
    stream << qint16(CHANNELS * BITS_PER_SAMPLE / 8);              // block align
    stream << qint16(BITS_PER_SAMPLE);
    // data
    stream.writeRawData("data", 4);
    stream << qint32(dataSize);

    m_outputFile->close();
    m_outputFile = nullptr;
}

void AudioRecorder::startRecording()
{
    if (m_isRecording)
        return;

    QString dataDir;
    if (m_saveAudio) {
        dataDir = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    } else {
        dataDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    }
    QDir().mkpath(dataDir + "/SpeechNotesExp");

    QString fileName = "recording_" + QString::number(QDateTime::currentMSecsSinceEpoch()) + ".wav";
    m_audioPath = dataDir + "/SpeechNotesExp/" + fileName;

    if (!openWavFile(m_audioPath, SAMPLE_RATE, CHANNELS, BITS_PER_SAMPLE)) {
        return;
    }

    QAudioFormat format;
    format.setSampleRate(SAMPLE_RATE);
    format.setChannelCount(CHANNELS);
    format.setSampleSize(BITS_PER_SAMPLE);
    format.setSampleType(QAudioFormat::SignedInt);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);

    QAudioDeviceInfo info = QAudioDeviceInfo::defaultInputDevice();
    if (!info.isFormatSupported(format)) {
        qWarning() << "Default audio format not supported, trying nearest";
        format = info.nearestFormat(format);
    }

    m_audioInput = new QAudioInput(info, format, this);
    m_audioInput->start(m_outputFile);

    m_isRecording = true;
    m_isPaused = false;
    m_duration = 0;
    m_elapsedTimer.start();
    m_durationTimer->start();

    emit recordingStateChanged();
    emit pausedStateChanged();
    emit durationChanged();

    qDebug() << "Recording started:" << m_audioPath;
}

void AudioRecorder::stopRecording()
{
    if (!m_isRecording)
        return;

    m_durationTimer->stop();

    if (m_audioInput) {
        m_audioInput->stop();
        m_audioInput->deleteLater();
        m_audioInput = nullptr;
    }

    finalizeWavFile();

    m_duration = m_elapsedTimer.elapsed();
    m_isRecording = false;
    m_isPaused = false;

    emit recordingStateChanged();
    emit pausedStateChanged();
    emit durationChanged();
    emit audioSaved(m_audioPath);

    qDebug() << "Recording stopped, duration:" << m_duration << "ms, file:" << m_audioPath;
}

void AudioRecorder::pauseRecording()
{
    if (!m_isRecording || m_isPaused || !m_audioInput)
        return;

    m_audioInput->suspend();
    m_durationTimer->stop();
    m_isPaused = true;
    emit pausedStateChanged();
    qDebug() << "Recording paused";
}

void AudioRecorder::resumeRecording()
{
    if (!m_isRecording || !m_isPaused || !m_audioInput)
        return;

    m_audioInput->resume();
    m_durationTimer->start();
    m_isPaused = false;
    emit pausedStateChanged();
    qDebug() << "Recording resumed";
}

void AudioRecorder::cancelRecording()
{
    if (!m_isRecording)
        return;

    m_durationTimer->stop();

    if (m_audioInput) {
        m_audioInput->stop();
        m_audioInput->deleteLater();
        m_audioInput = nullptr;
    }

    if (m_outputFile) {
        m_outputFile->close();
        m_outputFile = nullptr;
    }

    if (!m_tempPath.isEmpty()) {
        QFile::remove(m_tempPath);
    }

    m_isRecording = false;
    m_isPaused = false;
    m_duration = 0;

    emit recordingStateChanged();
    emit pausedStateChanged();
    emit durationChanged();
}

bool AudioRecorder::convertAudioToWav16k(const QString &sourcePath, const QString &targetPath)
{
    // Заглушка: пытаемся просто скопировать WAV PCM 16-bit, либо запустить ffmpeg
    QString ffmpeg = "/usr/bin/ffmpeg";
    if (QFile::exists(ffmpeg)) {
        QStringList args;
        args << "-y" << "-i" << sourcePath << "-ar" << "16000" << "-ac" << "1" << "-c:a" << "pcm_s16le" << targetPath;
        QProcess proc;
        proc.start(ffmpeg, args);
        if (!proc.waitForFinished(60000)) {
            qWarning() << "ffmpeg timeout for" << sourcePath;
            return false;
        }
        return proc.exitCode() == 0 && QFile::exists(targetPath);
    }

    // Если WAV уже 16kHz PCM mono — просто копируем
    if (sourcePath.toLower().endsWith(".wav")) {
        return QFile::copy(sourcePath, targetPath);
    }

    qWarning() << "No ffmpeg available and source is not WAV:" << sourcePath;
    return false;
}

QString AudioRecorder::importAudioFile(const QString &sourcePath)
{
    if (sourcePath.isEmpty() || !QFile::exists(sourcePath)) {
        emit error(tr("Source file not found"));
        return QString();
    }

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir + "/audio");

    QString fileName = "imported_" + QString::number(QDateTime::currentMSecsSinceEpoch()) + ".wav";
    QString targetPath = dataDir + "/audio/" + fileName;

    // Если WAV 16kHz mono PCM — копируем, иначе пытаемся ffmpeg-конвертировать
    bool ok = false;
    if (sourcePath.toLower().endsWith(".wav")) {
        ok = QFile::copy(sourcePath, targetPath);
    } else {
        ok = convertAudioToWav16k(sourcePath, targetPath);
    }

    if (ok && QFile::exists(targetPath)) {
        m_audioPath = targetPath;
        m_duration = 0;
        qDebug() << "Audio imported to:" << targetPath;
        return targetPath;
    }

    emit error(tr("Failed to import audio file"));
    return QString();
}

int AudioRecorder::getAudioDurationSec(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return 0;

    QByteArray data = file.readAll();
    file.close();

    if (data.size() < 44)
        return 0;

    const uchar *raw = reinterpret_cast<const uchar *>(data.constData());
    if (raw[0] != 'R' || raw[1] != 'I' || raw[2] != 'F' || raw[3] != 'F')
        return 0;

    int sampleRate = raw[24] | (raw[25] << 8) | (raw[26] << 16) | (raw[27] << 24);
    int channels = raw[22] | (raw[23] << 8);
    int bitsPerSample = raw[34] | (raw[35] << 8);

    if (sampleRate <= 0 || channels <= 0 || bitsPerSample <= 0)
        return 0;

    // Find data chunk
    int dataOffset = 44;
    for (int i = 12; i < data.size() - 8; ++i) {
        if (raw[i] == 'd' && raw[i+1] == 'a' && raw[i+2] == 't' && raw[i+3] == 'a') {
            dataOffset = i + 8;
            break;
        }
    }

    int dataSize = data.size() - dataOffset;
    int bytesPerSample = channels * (bitsPerSample / 8);
    if (bytesPerSample <= 0)
        return 0;

    int durationSec = dataSize / (sampleRate * bytesPerSample);
    qDebug() << "Audio duration:" << durationSec << "sec (size:" << dataSize << "sr:" << sampleRate << "ch:" << channels << "bps:" << bitsPerSample << ")";
    return durationSec;
}

void AudioRecorder::updateDuration()
{
    m_duration = m_elapsedTimer.elapsed();
    emit durationChanged();
}
