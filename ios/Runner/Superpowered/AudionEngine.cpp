#include "AudioEngine.h"
#include <iostream>

AudioEngine& AudioEngine::getInstance() {
    static AudioEngine instance;
    return instance;
}

void AudioEngine::init() {
    std::cout << "Superpowered Engine Init" << std::endl;
}

void AudioEngine::play() {
    std::cout << "Play audio engine" << std::endl;
}

void AudioEngine::pause() {
    std::cout << "Pause audio engine" << std::endl;
}