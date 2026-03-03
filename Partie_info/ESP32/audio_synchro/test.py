import socket
import numpy as np
import pyaudio

# --- CONFIGURATION ---
PORT = 12345
RATE = 16000  # Doit correspondre à sampleRate du Flutter
CHANNELS = 1  # On reçoit du Mono depuis Flutter

def start_audio_listener():
    # 1. Initialisation de PyAudio
    p = pyaudio.PyAudio()
    
    # 2. Ouverture du flux de sortie (enceintes)
    # On utilise un frames_per_buffer petit (512) pour réduire la latence
    stream = p.open(format=pyaudio.paInt16,
                    channels=CHANNELS,
                    rate=RATE,
                    output=True,
                    frames_per_buffer=512)

    # 3. Configuration du Socket UDP
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_sock.bind(("0.0.0.0", PORT))

    print(f"Écoute audio active sur le port {PORT}...")
    print("Appuie sur Ctrl+C pour arrêter.")

    try:
        while True:
            # On reçoit les données brutes du téléphone
            data, addr = server_sock.recvfrom(65535)
            
            if data:
                stream.write(data)
                
    except KeyboardInterrupt:
        print("\nArrêt de l'écoute.")
    finally:
        # Nettoyage
        stream.stop_stream()
        stream.close()
        p.terminate()
        server_sock.close()

if __name__ == "__main__":
    start_audio_listener()