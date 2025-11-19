from mutagen.mp3 import MP3 
from mutagen.id3 import ID3, APIC 
from mutagen.flac import FLAC, Picture
from PIL import Image 
import os
import base64 
import io 
import config


def extractTrackData(dossier, fichier):
    chemin = os.path.join(dossier, fichier)
    if fichier.lower().endswith('.mp3'):
        audio = MP3(chemin)
        tags = ID3(chemin)
        cover = getCompressedCoverBase64(dossier, fichier, file_type='mp3')
        title = str(tags.get('TIT2', ''))
        album = str(tags.get('TALB', ''))
        artist = str(tags.get('TPE2', ''))
        trackNumber = str(tags.get('TRCK', ''))
    elif fichier.lower().endswith('.flac'):
        audio = FLAC(chemin)
        title = audio.get('title', [''])[0]
        album = audio.get('album', [''])[0]
        artist = audio.get('artist', [''])[0]
        trackNumber = audio.get('tracknumber', [''])[0]
        cover = getCompressedCoverBase64(dossier, fichier, file_type='flac')
    else:
        return None

    return {
        'fileName': fichier,
        'title': title,
        'album': album,
        'artist': artist,
        'trackNumber': trackNumber,
        'duration': audio.info.length,
        'cover': cover,
    }

def getFolderContent(chemin_dossier): 
    try: 
        elements = os.listdir(chemin_dossier) 
        fichiers = [
            f for f in elements 
            if os.path.isfile(os.path.join(chemin_dossier, f))
        ] 
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
            return audio.info.length 
        else: 
            return None 
    except Exception as e: 
        print(f"Erreur lors de la lecture de {fichier}: {e}") 
        return None 
    
def getFileNameFromAlbum(albumName): 
    for file in config.tracklist: 
        if file["album"] == albumName: 
            return file["fileName"] 

def getMusicCoverBytes(chemin_dossier, fichier, file_type='mp3'):
    chemin_complet = os.path.join(chemin_dossier, fichier)
    try:
        if file_type == 'mp3':
            tags = ID3(chemin_complet)
            for tag in tags.values():
                if isinstance(tag, APIC):
                    return tag.data
        elif file_type == 'flac':
            audio = FLAC(chemin_complet)
            if audio.pictures:
                return audio.pictures[0].data
        return None
    except Exception as e:
        print(f"Erreur lors de la lecture de la cover de {fichier}: {e}")
        return None

def getCompressedCoverBase64(chemin_dossier, fichier, max_size=(300, 300), quality=70, file_type=None):
    if not file_type:
        file_type = 'mp3' if fichier.lower().endswith('.mp3') else 'flac'
    cover_bytes = getMusicCoverBytes(chemin_dossier, fichier, file_type)
    if not cover_bytes:
        return None
    try:
        image = Image.open(io.BytesIO(cover_bytes))
        image.thumbnail(max_size)
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=quality)
        return base64.b64encode(buffer.getvalue()).decode('utf-8')
    except Exception as e:
        print(f"Erreur lors de la compression de la cover de {fichier}: {e}")
        return None

def setTrackList(dossier):
    config.tracklist = []
    folderContent = getFolderContent(dossier)
    for file in folderContent:
        if not (file.lower().endswith('.mp3') or file.lower().endswith('.flac')):
            continue
        track_data = extractTrackData(dossier, file)
        if track_data:
            config.tracklist.append(track_data)

def getFileNameFromTitle(titleName):
    """Renvoie le nom du fichier correspondant au titre donné."""
    for file in config.tracklist:
        if file["title"] and file["title"].lower() == titleName.lower():
            return file["fileName"]
    return None

setTrackList(config.FOLDER)