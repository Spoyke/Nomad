import socket
import time
from pydub import AudioSegment

UDP_IP = "192.168.32.206"
UDP_PORT = 12345
CHUNK_SIZE = 128
SAMPLE_RATE = 8000
SAMPLE_WIDTH = 1# 8 bits
CHANNELS = 1# Mono
OUTPUT_FILE = "sent_data.txt" # Nom du fichier de sortie

# Créer le socket UDP
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Charger et convertir le MP3
audio = (
AudioSegment.from_mp3("Musique/Lindsey Stirling - Shatter Me Featuring Lzzy Hale.mp3")
.set_channels(CHANNELS)
.set_frame_rate(SAMPLE_RATE)
.set_sample_width(SAMPLE_WIDTH)
)

# Récupérer les données PCM brutes
data = audio.raw_data
duration_s = len(data) / SAMPLE_RATE
print(f"Durée du son : {duration_s:.2f} s")
print(f"Taille totale : {len(data)} octets")

# Calcul du délai exact pour un envoi temps réel
delay_s = CHUNK_SIZE / SAMPLE_RATE


# Envoi UDP et écriture dans le fichier
print("Début de la transmission...")
start_time = time.time()

# Ouvrir le fichier de sortie en mode écriture
with open(OUTPUT_FILE, 'w') as f:
    for i in range(0, len(data), CHUNK_SIZE):
        chunk = data[i:i + CHUNK_SIZE]
        sock.sendto(chunk, (UDP_IP, UDP_PORT))
        int_values = [str(b) for b in chunk]
        f.write(", ".join(int_values) + "\n")
        time.sleep(delay_s)

elapsed = time.time() - start_time
print(f"Transmission terminée en {elapsed:.2f} s")
print(f"Données écrites dans le fichier : {OUTPUT_FILE}")
sock.close()