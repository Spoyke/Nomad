import socket
import time
from pydub import AudioSegment

UDP_IP = "192.168.32.235"
UDP_PORT = 12345
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Convertir MP3 en PCM 8 bits mono
audio = AudioSegment.from_mp3("Musique/Le Tour.mp3").set_channels(1).set_frame_rate(8000).set_sample_width(1)
data = audio.raw_data

chunk_size = 128
delay_ms = 2  # en millisecondes

for i in range(0, len(data), chunk_size):
    chunk = data[i:i+chunk_size]
    sock.sendto(chunk, (UDP_IP, UDP_PORT))
    time.sleep(delay_ms / 1000)  # convertir ms en secondes
