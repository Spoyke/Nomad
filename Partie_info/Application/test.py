import socket
import numpy as np

# --- CONFIGURATION MULTICAST ---
MULTICAST_GROUP = "239.0.0.1"
PORT = 12345
MULTICAST_TTL = 2

def start_audio_multicast_bridge():
    # Socket d'envoi Multicast
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, MULTICAST_TTL)
    
    # Socket de réception (source audio locale)
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_sock.bind(("0.0.0.0", PORT))

    print(f"Pont Audio Multicast Opti : {MULTICAST_GROUP}:{PORT}")
    print("Signal de réveil envoyé...")
    
    try:
        # Réveil des ESP32
        sock.sendto(b"salut", (MULTICAST_GROUP, PORT))

        while True:
            data, addr = server_sock.recvfrom(65535)
            
            # Protection contre les boucles et filtrage
            if data and addr[0] != MULTICAST_GROUP:
                if data == b"salut":
                    continue
                
                # Conversion Mono -> Stéréo 16 bits
                # --- DANS TON CODE PYTHON ---
                gain = 0.1  # 50% du volume

                audio_data = np.frombuffer(data, dtype=np.int16)
                # On applique le volume ici (on convertit en float pour le calcul, puis on revient en int16)
                audio_data = (audio_data.astype(np.float32) * gain).astype(np.int16)

                stereo_data = np.repeat(audio_data, 2)
                byte_data = stereo_data.tobytes()
                
                # Taille de paquet optimisée pour le WiFi (1280 octets)
                # Cela réduit le nombre d'interruptions côté ESP32
                chunk_size = 1280                
                for i in range(0, len(byte_data), chunk_size):
                    chunk = byte_data[i:i + chunk_size]
                    sock.sendto(chunk, (MULTICAST_GROUP, PORT))
                    
    except KeyboardInterrupt:
        print("\nArrêt du pont.")
    finally:
        sock.close()
        server_sock.close()

if __name__ == "__main__":
    start_audio_multicast_bridge()