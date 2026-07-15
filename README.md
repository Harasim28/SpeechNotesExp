# SpeechNotes — Офлайн-распознавание речи и голосовые заметки

Диктофон с локальным распознаванием речи для ОС Аврора. Записывает аудио с микрофона, расшифровывает речь в текст прямо на устройстве (без интернета), сохраняет заметки с текстом и аудио, позволяет искать по тексту расшифровок.

## Возможности

- Запись аудио с микрофона (16 кГц, моно, PCM WAV)
- Офлайн-распознавание речи через whisper.cpp (без интернета и облака)
- Выбор модели: Whisper tiny (быстрая) или Whisper small (точная)
- Импорт аудиофайлов (WAV, MP3, OGG, FLAC, M4A) с конвертацией
- Сохранение заметок в JSON (заголовок, текст, дата, длительность)
- Просмотр и редактирование заметок
- История записей
- Сплэш-скрин, crossfade-анимации, cover page
- Иконка приложения 512x512 (уникальная)

## Модели

| Модель | Параметры | Размер (q8_0) | Скорость |
|--------|-----------|---------------|----------|
| Whisper tiny | 39M | 42 МБ | ~14с/1с аудио |
| Whisper small | 244M | 253 МБ | ~60с/1с аудио |

Формат: GGML q8_0 (квантованные, для whisper.cpp).

## Технологии

- C++ / Qt 5.6 / QML / Sailfish.Silica
- whisper.cpp (статическая линковка, без ONNX Runtime)
- GGML формат моделей с INT8 квантизацией
- QtConcurrent (инференс в фоновом потоке)
- qmake + Docker (кросс-компиляция armv7hl)

## Структура

```
src/         — C++ исходники (AudioRecorder, TranscriptWorker, NoteModel)
qml/         — QML интерфейс (Silica)
  SpeechNotes.qml    — главное окно с табами
  pages/MainPage.qml — запись + импорт
  pages/NotesPage.qml — список заметок
  pages/NotesEditorPage.qml — редактор
  pages/SettingsPage.qml — выбор модели
  pages/HistoryPage.qml — история
  SplashScreen.qml — сплэш-скрин
  TabButton.qml — кнопки табов с SVG-иконками
  cover/DefaultCoverPage.qml — cover page
models/      — GGML модели (tiny + small)
lib/armv7hl/ — статические библиотеки whisper.cpp
icons/       — иконки приложения (86/108/128/172 + 512)
rpm/         — spec-файл для сборки RPM
```

## Команда

См. AUTHORS.md