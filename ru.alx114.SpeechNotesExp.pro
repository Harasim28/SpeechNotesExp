TARGET = ru.alx114.SpeechNotesExp

CONFIG += auroraapp

PKGCONFIG += auroraapp

QT += quick qml gui core concurrent

SOURCES += src/main.cpp \
    src/audiorecorder.cpp \
    src/transcriptworker.cpp \
    src/notemodel.cpp

HEADERS += src/audiorecorder.h \
    src/transcriptworker.h \
    src/notemodel.h \
    src/whisper.h \
    src/ggml.h \
    src/ggml-alloc.h \
    src/ggml-backend.h \
    src/ggml-cpu.h

CONFIG += link_pkgconfig
PKGCONFIG += Qt5Multimedia

INCLUDEPATH += $$PWD/lib/armv7hl
LIBS += $$PWD/lib/armv7hl/libwhisper.a \
        $$PWD/lib/armv7hl/libggml.a \
        $$PWD/lib/armv7hl/libggml-base.a \
        $$PWD/lib/armv7hl/libggml-cpu.a \
        $$PWD/lib/armv7hl/libparakeet.a \
        -lm -lpthread

QMAKE_LFLAGS += -Wl,-rpath,/usr/share/ru.alx114.SpeechNotesExp/lib

models.files = models/ggml-tiny-q8_0.bin models/ggml-small-q8_0.bin
models.path = /usr/share/ru.alx114.SpeechNotesExp/models
INSTALLS += models

testaudio.files = test-audio/test_16k.wav
testaudio.path = /usr/share/ru.alx114.SpeechNotesExp/test-audio
INSTALLS += testaudio

DISTFILES += rpm/ru.alx114.SpeechNotesExp.spec
AURORAAPP_ICONS = 86x86 108x108 128x128 172x172
