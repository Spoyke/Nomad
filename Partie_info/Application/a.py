import socket
import numpy as np
import pyaudio

# --- CONFIGURATION ---
MULTICAST_GROUP = "239.0.0.1"
PORT = 12345
MULTICAST_TTL = 2
VOLUME = 1.0
CHANNELS = 1 # Ton entrée semble être du mono d'après ton code
RATE = 44100 # À ajuster selon la fréquence de ta source (ex: 44100 ou 48000)

def start_audio_multicast_bridge():
    # Initialisation PyAudio
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16,
                    channels=CHANNELS,
                    rate=RATE,
                    output=True)

    # Socket d'envoi Multicast
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, MULTICAST_TTL)
    
    # Socket de réception
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_sock.bind(("0.0.0.0", PORT))

    print(f"Pont Audio + Lecture locale active sur {MULTICAST_GROUP}:{PORT}")
    
    try:
        sock.sendto(b"salut", (MULTICAST_GROUP, PORT))

        while True:
            data, addr = server_sock.recvfrom(65535)
            
            if data and addr[0] != MULTICAST_GROUP:
                if data == b"salut":
                    continue
                
                # Conversion brute
                audio_data = np.frombuffer(data, dtype=np.int16)
                
                # Application du volume
                if VOLUME != 1.0:
                    audio_data = (audio_data.astype(np.float32) * VOLUME).astype(np.int16)

                # --- LECTURE AUDIO LOCALE ---
                # On joue le mono original avant la conversion stéréo pour le réseau
                stream.write(audio_data.tobytes())

                # Conversion Stéréo pour le Multicast (ESP32)
                stereo_data = np.repeat(audio_data, 2)
                byte_data = stereo_data.tobytes()
                
                # Envoi par morceaux
                chunk_size = 1280                
                for i in range(0, len(byte_data), chunk_size):
                    chunk = byte_data[i:i + chunk_size]
                    sock.sendto(chunk, (MULTICAST_GROUP, PORT))
                    
    except KeyboardInterrupt:
        print("\nArrêt du pont.")
    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()
        sock.close()
        server_sock.close()

if __name__ == "__main__":
    start_audio_multicast_bridge()