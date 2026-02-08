import socket
import numpy as np
import time

# --- CONFIGURATION ---
PYTHON_IP = "0.0.0.0"
PYTHON_PORT = 12345

ESP32_IP = "10.42.0.108"
ESP32_PORT = 12345

def start_audio_bridge():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
    sock.bind((PYTHON_IP, PYTHON_PORT))

    print(f"Pont Audio actif : Port {PYTHON_PORT} -> ESP32 {ESP32_IP}")
    sock.sendto(b"salut", (ESP32_IP, ESP32_PORT))
    try:
        while True:
            data, addr = sock.recvfrom(65535)
            if data:
                if data == b"salut":
                    continue
                audio_data = np.frombuffer(data, dtype=np.int16)
                stereo_data = np.repeat(audio_data, 2)
                byte_data = stereo_data.tobytes()
                chunk_size = 1024                
                for i in range(0, len(byte_data), chunk_size):
                    chunk = byte_data[i:i + chunk_size]
                    sock.sendto(chunk, (ESP32_IP, ESP32_PORT))
    except KeyboardInterrupt:
        print("\nArrêt du serveur.")
    finally:
        sock.close()
if __name__ == "__main__":
    start_audio_bridge()