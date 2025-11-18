import subprocess
import sys
import time

# --- Configuration ---
# L'URL Icecast est fixe (le destinataire)
ICECAST_URL = "icecast://source:hackme@10.30.192.117:8000/stream.mp3"

def start_stream(input_file: str):
    """
    Démarre le streaming d'un fichier audio vers Icecast.
    Le fichier d'entrée (input_file) peut être .mp3, .wav, .flac, etc.
    """
    
    # 1. Définition de la liste d'arguments FFMPEG
    # Notez que {input_file} est maintenant une variable
    FFMPEG_COMMAND_LIST = [
        "ffmpeg",
        "-re",  # Lit l'entrée à sa vitesse native
        "-i", input_file,  # <-- C'est ici qu'on utilise le fichier .wav ou .mp3
        "-vn",  # Pas de vidéo
        "-c:a", "libmp3lame", # Encodage en MP3
        "-b:a", "128k", # Débit binaire
        "-f", "mp3",  # Format de sortie
        ICECAST_URL
    ]

    print(f"Démarrage du streaming de '{input_file}' vers Icecast...")
    print("-" * 50)
    
    try:
        # 2. Exécution de la commande via subprocess.Popen
        process = subprocess.Popen(
            FFMPEG_COMMAND_LIST,
            stdout=sys.stdout,
            stderr=sys.stderr
        )
        
        print(f"Processus FFmpeg démarré (PID: {process.pid}). En attente...")

        # 3. Boucle principale pour maintenir le script actif
        while True:
            time.sleep(1)
            if process.poll() is not None:
                print(f"\nLe processus FFmpeg s'est terminé avec le code : {process.returncode}")
                break

    except KeyboardInterrupt:
        # Gestion de l'arrêt avec CTRL+C
        print("\nArrêt du streaming demandé par l'utilisateur (CTRL+C)...")
        if process.poll() is None:
            process.terminate()
        process.wait(timeout=5)
        print("Streaming arrêté.")
        
    except FileNotFoundError:
        print("\nERREUR FATALE : Le programme 'ffmpeg' est introuvable. (Vérifiez le PATH)")
    except Exception as e:
        print(f"\nUne erreur inattendue est survenue : {e}")


if __name__ == "__main__":
    # --- Utilisation du nouveau code ---
    
    # Pour lire votre MP3 original:
    start_stream("Musique/EARTHGANG - Act Up.flac")
    
    # Pour lire un fichier WAV (assurez-vous que le fichier existe!)
    # Décommentez la ligne suivante pour tester le WAV
    # start_stream("Musique/mon_super_son.wav")