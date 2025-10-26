import socket
import time
from pydub import AudioSegment

UDP_IP = "192.168.32.206"
UDP_PORT = 12345
CHUNK_SIZE = 128
SAMPLE_RATE = 8000
SAMPLE_WIDTH = 1
CHANNELS = 1

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

audio = (
    AudioSegment.from_mp3("Musique/Le Tour.mp3")
    .set_channels(CHANNELS)
    .set_frame_rate(SAMPLE_RATE)
    .set_sample_width(SAMPLE_WIDTH)
)

data = audio.raw_data
data = bytes((b + 128) % 256 for b in data)  # Décalage pour PCM non signé

delay_s = CHUNK_SIZE / SAMPLE_RATE
print("Début de la transmission...")

for i in range(0, len(data), CHUNK_SIZE):
    chunk = data[i:i + CHUNK_SIZE]
    sock.sendto(chunk, (UDP_IP, UDP_PORT))
    time.sleep(delay_s)

print("Transmission terminée.")
sock.close()
