import subprocess
import time
import os
import sys
import threading
import re
import ip

# ICECAST_URL = "icecast://source:hackme@192.168.1.12:8000/stream.mp3"
ICECAST_START = "icecast://source:hackme@"
ICECAST_END = ":8000/stream.mp3"
processus_ffmpeg = None
dernier_temps = 0.0  # secondes
start_offset = 0.0   # secondes

def verifier_fichier(fichier):
    if not os.path.exists(fichier):
        print(f"Erreur : le fichier '{fichier}' n'existe pas.")
        return False
    print("Fichier trouvé :", fichier)
    return True


def construire_commande(fichier, start_time=5):
    ext = os.path.splitext(fichier)[1].lower()
    FORMATS_A_ENCODER = ['.wav', '.flac', '.ogg', '.m4a']
    cmd = ["ffmpeg", "-re", "-nostdin", "-vn"]

    if start_time > 0:
        cmd += ["-ss", str(start_time)]

    cmd += ["-i", fichier]

    if ext == ".mp3":
        cmd += ["-c:a", "copy"]
    elif ext in FORMATS_A_ENCODER:
        cmd += ["-c:a", "libmp3lame", "-b:a", "128k"]
    else:
        print(f"Erreur : extension '{ext}' non prise en charge.")
        return None
    url = ICECAST_START + ip.get_local_ip() +  ICECAST_END
    print(url)
    cmd += ["-f", "mp3", url]
    return cmd


def _parse_time_to_seconds(tstr):
    try:
        h, m, s = tstr.split(':')
        return float(h) * 3600 + float(m) * 60 + float(s)
    except Exception:
        return 0.0

def _diffuser_thread(cmd, start_time):
    global processus_ffmpeg, dernier_temps, start_offset
    start_offset = float(start_time)
    try:
        processus_ffmpeg = subprocess.Popen(cmd, stderr=subprocess.PIPE, universal_newlines=True)

        for line in processus_ffmpeg.stderr:
            if "time=" in line:
                match = re.search(r"time=(\d+:\d+:\d+\.\d+)", line)
                if match:
                    t = _parse_time_to_seconds(match.group(1))
                    dernier_temps = t + start_offset  # on ajoute le décalage initial
                sys.stdout.write(f"\rTemps total : {dernier_temps:.2f} s")
                sys.stdout.flush()
            elif "Error" in line:
                print("\nErreur FFmpeg :", line.strip())
                break

        processus_ffmpeg.wait()
        print("\nDiffusion terminée.")
    except Exception as e:
        print("\nErreur ou interruption de la diffusion :", e)
    finally:
        if processus_ffmpeg:
            if processus_ffmpeg.poll() is None:
                processus_ffmpeg.terminate()
            processus_ffmpeg = None
            print("Thread de diffusion nettoyé.")


def lancer_diffusion(fichier, start_time=5):
    global processus_ffmpeg

    if processus_ffmpeg and processus_ffmpeg.poll() is None:
        print("Erreur : Une diffusion est déjà en cours.")
        return

    if not verifier_fichier(fichier):
        print("Fichier non trouvé : " + fichier)
        return

    cmd = construire_commande(fichier, start_time)
    if not cmd:
        return

    thread = threading.Thread(target=_diffuser_thread, args=(cmd, start_time), daemon=True)
    thread.start()
    print(f"Thread de diffusion lancé pour : {fichier}, départ à {start_time} s")


def stopper_diffusion():
    global processus_ffmpeg, dernier_temps

    if processus_ffmpeg and processus_ffmpeg.poll() is None:
        print("Arrêt de la diffusion en cours...")
        try:
            processus_ffmpeg.terminate()
            processus_ffmpeg.wait(timeout=5)
            print("Diffusion arrêtée.")
        except subprocess.TimeoutExpired:
            print("Le processus n'a pas répondu, forçage (kill)...")
            processus_ffmpeg.kill()
            processus_ffmpeg.wait()
            print("Diffusion forcée à l'arrêt.")
        finally:
            processus_ffmpeg = None
            print(f"Dernier temps lu total : {dernier_temps:.2f} secondes")
            return dernier_temps
    else:
        print("Aucune diffusion en cours.")
        return dernier_temps
