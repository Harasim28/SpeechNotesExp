// Minimal whisper.cpp test - no Qt, just whisper
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

extern "C" {
#include "whisper.h"
}

// Load 16-bit mono WAV, return float samples
static float *load_wav(const char *path, int *n_samples) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "Cannot open %s\n", path); return NULL; }
    
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    unsigned char *data = (unsigned char*)malloc(size);
    fread(data, 1, size, f);
    fclose(f);
    
    if (size < 44 || data[0]!='R' || data[1]!='I' || data[2]!='F' || data[3]!='F') {
        fprintf(stderr, "Not RIFF\n");
        free(data);
        return NULL;
    }
    
    int channels = data[22] | (data[23]<<8);
    int sampleRate = data[24]|(data[25]<<8)|(data[26]<<16)|(data[27]<<24);
    int bps = data[34]|(data[35]<<8);
    
    int dataOff = 44;
    for (int i=12; i<size-8; ++i) {
        if (data[i]=='d'&&data[i+1]=='a'&&data[i+2]=='t'&&data[i+3]=='a') {
            dataOff = i+8; break;
        }
    }
    
    fprintf(stderr, "WAV: ch=%d sr=%d bps=%d off=%d size=%ld\n", channels, sampleRate, bps, dataOff, size);
    
    if (bps != 16) { fprintf(stderr, "Not 16-bit\n"); free(data); return NULL; }
    
    int n = (size - dataOff) / (channels * 2);
    float *samples = (float*)malloc(n * sizeof(float));
    short *s = (short*)(data + dataOff);
    for (int i=0; i<n; ++i) {
        float sum = 0;
        for (int c=0; c<channels; ++c) sum += s[i*channels+c] / 32768.0f;
        samples[i] = sum / channels;
    }
    *n_samples = n;
    free(data);
    fprintf(stderr, "Loaded %d samples\n", n);
    return samples;
}

int main(int argc, char **argv) {
    const char *modelPath = "/usr/share/ru.alx114.SpeechNotesExp/models/ggml-tiny-q8_0.bin";
    const char *wavPath = "/usr/share/ru.alx114.SpeechNotesExp/test-audio/test_16k.wav";
    
    if (argc > 1) modelPath = argv[1];
    if (argc > 2) wavPath = argv[2];
    
    fprintf(stderr, "Model: %s\n", modelPath);
    fprintf(stderr, "WAV: %s\n", wavPath);
    
    fprintf(stderr, "Creating context...\n");
    whisper_context_params cparams = whisper_context_default_params();
    whisper_context *ctx = whisper_init_from_file_with_params(modelPath, cparams);
    if (!ctx) { fprintf(stderr, "FAILED to create context\n"); return 1; }
    fprintf(stderr, "Context OK\n");
    
    int n_samples = 0;
    float *samples = load_wav(wavPath, &n_samples);
    if (!samples) { whisper_free(ctx); return 1; }
    
    fprintf(stderr, "Running whisper_full (1 thread)...\n");
    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.translate = false;
    params.language = "ru";
    params.n_threads = 1;
    params.print_progress = true;
    params.print_special = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    
    int ret = whisper_full(ctx, params, samples, n_samples);
    fprintf(stderr, "whisper_full returned: %d\n", ret);
    
    int nSeg = whisper_full_n_segments(ctx);
    fprintf(stderr, "Segments: %d\n", nSeg);
    for (int i=0; i<nSeg; ++i) {
        const char *text = whisper_full_get_segment_text(ctx, i);
        fprintf(stderr, "Seg %d: [%s]\n", i, text ? text : "(null)");
        printf("%s ", text ? text : "");
    }
    printf("\n");
    
    free(samples);
    whisper_free(ctx);
    fprintf(stderr, "DONE\n");
    return 0;
}