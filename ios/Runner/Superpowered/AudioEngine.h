#pragma once

class AudioEngine {
public:
    static AudioEngine& getInstance();

    void init();
    void play();
    void pause();

private:
    AudioEngine() {}
};