import os
from mutagen.mp3 import MP3
from mutagen.id3 import ID3

def getFolderContent(chemin_dossier):
    try:
        elements = os.listdir(chemin_dossier)
        fichiers = [f for f in elements if os.path.isfile(os.path.join(chemin_dossier, f))]
        return fichiers
    except FileNotFoundError:
        return f"Le dossier '{chemin_dossier}' n'existe pas."
    except Exception as e:
        return f"Une erreur s'est produite : {e}"

def getMusicDuration(chemin_dossier, fichier):
    try:
        chemin_complet = os.path.join(chemin_dossier, fichier)
        if fichier.endswith('.mp3'):
            audio = MP3(chemin_complet)
            return audio.info.length  # Durée en secondes
        else:
            return None  # Format non supporté
    except Exception as e:
        print(f"Erreur lors de la lecture de {fichier}: {e}")
        return None

def getAllMusicDurations(chemin_dossier):
    fichiers = getFolderContent(chemin_dossier)
    if isinstance(fichiers, str):
        print(fichiers)  # Affiche le message d'erreur
        return []

    musiques_avec_duree = []
    for fichier in fichiers:
        duree = getMusicDuration(chemin_dossier, fichier)
        if duree is not None:
            musiques_avec_duree.append({
                "nom": fichier,
                "duree": duree
            })

    return musiques_avec_duree

