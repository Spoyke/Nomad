import socket
import numpy as np
import pyaudio
import time
# --- CONFIGURATION ---
UDP_PORT = 12345
MULTICAST_GROUP = "239.0.0.1"
RATE = 16000  # Sample rate de Flutter
CHANNELS_IN = 1 # Mono depuis Flutter

# --- INITIALISATION AUDIO LOCALE ---
p = pyaudio.PyAudio()
stream = p.open(format=pyaudio.paInt16,
                channels=CHANNELS_IN,
                rate=RATE,
                output=True,
                frames_per_buffer=512)

# --- INITIALISATION RÉSEAU ---
# Socket pour recevoir de Flutter
recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
recv_sock.bind(("0.0.0.0", UDP_PORT))

# Socket pour envoyer en Multicast vers l'ESP32
send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
send_sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)

def start_bridge():
    print(f"Relais actif : Réception UDP -> Lecture Locale -> Multicast {MULTICAST_GROUP}")
    
    try:
        while True:
            # 1. Réception du flux Flutter
            data, addr = recv_sock.recvfrom(65535)
            
            if data:
                # Filtrage du message de réveil pour ne pas l'envoyer aux enceintes
                if data.startswith(b"salut"):
                    # On relaie le salut à l'ESP32 pour qu'il switch en mode 16kHz
                    send_sock.sendto(data, (MULTICAST_GROUP, UDP_PORT))
                    continue

                # 2. Lecture sur l'ordinateur
                # stream.write(data)

                # 3. Préparation pour l'ESP32 (Conversion Mono -> Stéréo)
                # L'ESP32 attend du Stéréo (len % 4 == 0) selon ton code
                audio_np = np.frombuffer(data, dtype=np.int16)
                
                # Si le paquet est trop petit, on l'ignore pour éviter les clics
                if len(audio_np) < 16: 
                    continue
                stereo_np = np.repeat(audio_np, 2)
                stereo_data = stereo_np.tobytes()

                # 4. Envoi Multicast par petits paquets (MTU WiFi ~1400 octets)
                # On découpe pour éviter de perdre des paquets trop gros sur l'ESP32
                chunk_size = 1280
                for i in range(0, len(stereo_data), chunk_size):
                    chunk = stereo_data[i:i + chunk_size]
                    send_sock.sendto(chunk, (MULTICAST_GROUP, UDP_PORT))
                    # Laisser un peu d'air à l'ESP32 (environ 1-2ms)
                    time.sleep(0.001)

    except KeyboardInterrupt:
        print("\nArrêt du relais.")
    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()
        recv_sock.close()
        send_sock.close()

if __name__ == "__main__":
    start_bridge()