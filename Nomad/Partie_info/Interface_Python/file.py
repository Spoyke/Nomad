import os
from mutagen.mp3 import MP3
from mutagen.id3 import ID3
from PIL import Image
import io
from mutagen.id3 import ID3, APIC
import base64
import os
import json


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
            # print(audio.tags.get("TIT2"))
            return audio.info.length  # Durée en secondes
        else:
            return None  # Format non supporté
    except Exception as e:
        print(f"Erreur lors de la lecture de {fichier}: {e}")
        return None

def getMusicCoverBytes(chemin_dossier, fichier):
    chemin_complet = os.path.join(chemin_dossier, fichier)
    if not fichier.endswith('.mp3'):
        return None
    tags = ID3(chemin_complet)
    for tag in tags.values():
        if isinstance(tag, APIC):
            # print(tag.data)
            return tag.data
    return None


def getTrackList(dossier):
    trackList = []
    folderContent = getFolderContent(dossier)
    for file in folderContent:
        cover_bytes = getMusicCoverBytes(dossier, file)
        cover_base64 = base64.b64encode(cover_bytes).decode('utf-8') if cover_bytes else None
        
        track = {
            'title': file,
            'duration': getMusicDuration(dossier, file),
            'cover': cover_base64,
        }
        trackList.append(track)
    return json.dumps(trackList)
