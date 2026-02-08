#include "MyI2S.h"

// Note : Pour le micro, la fréquence sera ajustée par playChunk, 
// mais on garde 44100 pour Icecast.
#define I2S_SAMPLE_RATE 44100
#define I2S_BCK_IO      10     // BCLK
#define I2S_WS_IO       11     // LRCLK
#define I2S_DO_IO       12     // Data out
#define SD_PIN          5 

Audio audio;
int volume = 3;

void Audio_init(){
    // La bibliothèque gère l'installation du driver I2S d'Espressif pour nous
    audio.setPinout(I2S_BCK_IO, I2S_WS_IO, I2S_DO_IO);
    audio.setVolume(volume);
}

void Audio_loop(){
    audio.loop();
}

// --- AJOUT : Fonction pour jouer les données UDP ---
void playUdpChunk(uint8_t* data, size_t len) {
    size_t bytesWritten;
    // On écrit les données dans l'I2S. 
    // Le timeout (10) permet de ne pas faire ramer le reste du code
    i2s_write(I2S_NUM_0, data, len, &bytesWritten, 10);
}

void startAudio(const char* url) {
    Serial.println("Connexion au flux audio...");
    audio.setVolume(volume);
    audio.connecttohost(url);
}

void stopAudio() {
    if(audio.isRunning()){
        audio.stopSong();
        Serial.println("Lecture arrêtée.");
    }
}

void setVolumeLevel(int vol){
    volume = vol;
    audio.setVolume(volume);
}