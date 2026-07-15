#include "notemodel.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDebug>
#include <QDir>
#include <algorithm>

NoteModel::NoteModel(QObject *parent) : QAbstractListModel(parent)
{
    loadFromFile();
}

int NoteModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_notes.count();
}

QVariant NoteModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_notes.count())
        return QVariant();

    const Note &note = m_notes.at(index.row());

    switch (role) {
    case IdRole: return note.id;
    case TitleRole: return note.title;
    case TextRole: return note.text;
    case AudioPathRole: return note.audioPath;
    case CreatedAtRole: return note.createdAt;
    case DurationRole: return note.durationSec;
    case PinnedRole: return note.pinned;
    default: return QVariant();
    }
}

QHash<int, QByteArray> NoteModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "noteId";
    roles[TitleRole] = "title";
    roles[TextRole] = "text";
    roles[AudioPathRole] = "audioPath";
    roles[CreatedAtRole] = "createdAt";
    roles[DurationRole] = "duration";
    roles[PinnedRole] = "pinned";
    return roles;
}

void NoteModel::addNote(const QString &title, const QString &text,
                        const QString &audioPath, int durationSec)
{
    if (text.isEmpty())
        return;

    Note note;
    note.id = QString::number(QDateTime::currentMSecsSinceEpoch());
    note.title = title.isEmpty() ? text.left(30) + "..." : title;
    note.text = text;
    note.audioPath = audioPath;
    note.createdAt = QDateTime::currentDateTime();
    note.durationSec = durationSec;
    note.pinned = false;

    beginInsertRows(QModelIndex(), 0, 0);
    m_notes.prepend(note);
    endInsertRows();

    // Сортируем чтобы закреплённые остались вверху
    sortNotesInternal(m_sortMode);

    emit countChanged();
    saveToFile();

    qDebug() << "📝 Note added:" << note.title;
}

void NoteModel::removeNote(int index)
{
    if (index < 0 || index >= m_notes.count())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_notes.removeAt(index);
    endRemoveRows();

    emit countChanged();
    saveToFile();

    qDebug() << "🗑️ Note removed at index:" << index;
}

void NoteModel::clearAll()
{
    if (m_notes.isEmpty())
        return;

    beginResetModel();
    m_notes.clear();
    endResetModel();

    emit countChanged();
    saveToFile();

    qDebug() << "🗑️ All notes cleared";
}

QString NoteModel::getNoteText(int index) const
{
    if (index < 0 || index >= m_notes.count())
        return QString();

    return m_notes.at(index).text;
}

void NoteModel::updateNote(int index, const QString &title, const QString &text)
{
    if (index < 0 || index >= m_notes.count())
        return;

    m_notes[index].title = title.isEmpty() ? text.left(30) + "..." : title;
    m_notes[index].text = text;

    emit dataChanged(this->index(index, 0), this->index(index, 0));
    saveToFile();
}

void NoteModel::togglePin(int index)
{
    if (index < 0 || index >= m_notes.count())
        return;

    m_notes[index].pinned = !m_notes[index].pinned;
    sortNotesInternal(m_sortMode);
    saveToFile();

    qDebug() << "⭐ Note pin toggled at index:" << index;
}

void NoteModel::sortNotes(int mode)
{
    m_sortMode = mode;
    sortNotesInternal(mode);
    saveToFile();

    qDebug() << "Notes sorted, mode:" << mode;
}

void NoteModel::sortNotesInternal(int mode)
{
    int sortMode = (mode >= 0 && mode <= 2) ? mode : m_sortMode;

    beginResetModel();

    std::sort(m_notes.begin(), m_notes.end(), [sortMode](const Note &a, const Note &b) {
        if (a.pinned != b.pinned)
            return a.pinned > b.pinned;

        if (sortMode == 0)
            return a.createdAt > b.createdAt;
        else if (sortMode == 1)
            return a.createdAt < b.createdAt;
        else
            return QString::compare(a.title, b.title, Qt::CaseInsensitive) < 0;
    });

    endResetModel();
    emit countChanged();
}

QVariantMap NoteModel::getNote(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_notes.count())
        return map;

    const Note &note = m_notes.at(index);
    map["id"] = note.id;
    map["title"] = note.title;
    map["text"] = note.text;
    map["audioPath"] = note.audioPath;
    map["createdAt"] = note.createdAt;
    map["durationSec"] = note.durationSec;
    map["pinned"] = note.pinned;
    return map;
}

void NoteModel::saveToFile()
{
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);

    QFile file(dataDir + "/notes.json");
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Cannot save notes:" << file.errorString();
        return;
    }

    QJsonArray array;
    for (const Note &note : m_notes) {
        QJsonObject obj;
        obj["id"] = note.id;
        obj["title"] = note.title;
        obj["text"] = note.text;
        obj["audioPath"] = note.audioPath;
        obj["createdAt"] = note.createdAt.toString(Qt::ISODate);
        obj["durationSec"] = note.durationSec;
        obj["pinned"] = note.pinned;
        array.append(obj);
    }

    file.write(QJsonDocument(array).toJson());
    qDebug() << "💾 Saved" << m_notes.count() << "notes";
}

void NoteModel::loadFromFile()
{
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QFile file(dataDir + "/notes.json");
    if (!file.exists())
        return;

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot load notes:" << file.errorString();
        return;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray())
        return;

    QJsonArray array = doc.array();
    m_notes.clear();

    for (const QJsonValue &value : array) {
        QJsonObject obj = value.toObject();
        Note note;
        note.id = obj["id"].toString();
        note.title = obj["title"].toString();
        note.text = obj["text"].toString();
        note.audioPath = obj["audioPath"].toString();
        note.createdAt = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODate);
        note.durationSec = obj["durationSec"].toInt();
        note.pinned = obj["pinned"].toBool();

        if (!note.id.isEmpty() && !note.text.isEmpty()) {
            m_notes.append(note);
        }
    }

    emit countChanged();
    qDebug() << "📂 Loaded" << m_notes.count() << "notes from file";
}
