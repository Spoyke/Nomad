# --- IMPORTS DE BIBLIOTHÈQUES STANDARDS (Début du fichier) ---
import socket
import os
import subprocess
import sys
import threading
import time 

# ====================================================
# CONFIGURATION ET VARIABLES GLOBALES
# ====================================================

# Variables pour la connexion Icecast
ICECAST_START = "icecast://source:hackme@"
ICECAST_END   = ":8000/stream.mp3"

# Processus FFmpeg (contrôlé par le thread)
process_ffmpeg = None 

# ====================================================
# GESTION DU RÉSEAU LOCAL (IP)
# ====================================================

def get_local_ip():
    """Tente de déterminer l'adresse IP locale de la machine."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

# ====================================================
# PRÉPARATION DES FICHIERS ET COMMANDE FFmpeg
# ====================================================

def verifier_fichier(fichier):
    """Vérifie l'existence du fichier audio."""
    if not os.path.exists(fichier):
        print(f"Erreur : le fichier '{fichier}' n'existe pas.")
        return False
    print("Fichier trouvé :", fichier)
    return True

def construire_commande(fichier):
    """Construit la commande FFmpeg pour l'encodage et le stream."""
    ext = os.path.splitext(fichier)[1].lower()
    FORMATS_A_ENCODER = ['.wav', '.flac', '.ogg', '.m4a']

    cmd = [
        "ffmpeg",
        "-re",
        "-nostdin",
        "-vn",
        "-i", fichier,
    ]

    # Logique d'encodage
    if ext == ".mp3":
        cmd += ["-c:a", "copy"]
        print(f"DEBUG: Fichier MP3 détecté, aucun réencodage.")
    elif ext in FORMATS_A_ENCODER:
        cmd += ["-c:a", "libmp3lame", "-b:a", "128k"]
        print(f"DEBUG: Fichier {ext} détecté, réencodage vers MP3 (128k).")
    else:
        print(f"Erreur : extension '{ext}' non prise en charge.")
        return None
        
    # Destination Icecast
    url = ICECAST_START + get_local_ip() + ICECAST_END
    print(f"URL de destination Icecast: {url}")
    cmd += ["-f", "mp3", url]
    return cmd

# ====================================================
# GESTION DU THREAD ET DU PROCESSUS FFmpeg
# ====================================================

def _diffuser_thread(cmd):
    """Fonction interne exécutée dans un thread pour la diffusion."""
    global process_ffmpeg
    # NOTE: Ici vous pouvez ajouter la logique d'extraction du temps de diffusion
    # ...
    
    try:
        print("Démarrage de la diffusion...")
        process_ffmpeg = subprocess.Popen(cmd, stderr=subprocess.PIPE, universal_newlines=True)

        for line in process_ffmpeg.stderr:
            if "Error" in line:
                print("Erreur FFmpeg :", line.strip())
                break
            if "size=" in line and "time=" in line:
                sys.stdout.write(f"\r{line.strip()}")
                sys.stdout.flush()

        print("\nDiffusion terminée.")
    except Exception as e:
        print("Erreur dans la diffusion :", e)
    finally:
        if process_ffmpeg:
            process_ffmpeg.terminate()
            process_ffmpeg = None

def arreter_diffusion():
    """Arrête la diffusion en cours si elle est active."""
    global process_ffmpeg
    if process_ffmpeg and process_ffmpeg.poll() is None:
        print("Arrêt de la diffusion...")
        process_ffmpeg.terminate()
        process_ffmpeg.wait()
        process_ffmpeg = None
        print("Diffusion arrêtée.")
    else:
        print("Aucune diffusion en cours.")

def diffuser(cmd):
    """Lance la diffusion dans un thread (non bloquant)."""
    if process_ffmpeg and process_ffmpeg.poll() is None:
        arreter_diffusion()
         
    thread = threading.Thread(target=_diffuser_thread, args=(cmd,), daemon=True)
    thread.start()
    print("Thread de diffusion lancé.")

