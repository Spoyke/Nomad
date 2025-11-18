import os 
from mutagen.mp3 import MP3 
from mutagen.id3 import ID3, APIC 
from PIL import Image 
import base64 
import io 
import json 

tagList = {
    'artist' : 'TPE2',
    'title' : 'TIT2',
    'trackNumber': 'TRCK',
    'album ': 'TALB',
}

music_folder = "Musique"

trackList = [] 

def getTrackInfo(dossier, fichier, tag):
    chemin_complet = os.path.join(dossier, fichier) 
    if not fichier.endswith('.mp3'): 
        return None 
    try: 
        audio = ID3(chemin_complet) 
        album = audio.get(tag) 
        return str(album) if album else None 
    except Exception as e: 
        print(f"Erreur lors de la lecture de {tag} de {fichier}: {e}") 
        return None 

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
    for file in trackList: 
        if file["album"] == albumName: 
            return file["fileName"] 

def getMusicCoverBytes(chemin_dossier, fichier): 
    chemin_complet = os.path.join(chemin_dossier, fichier) 
    if not fichier.endswith('.mp3'): 
        return None 
    try: 
        tags = ID3(chemin_complet) 
        for tag in tags.values(): 
            if isinstance(tag, APIC): 
                return tag.data 
        return None 
    except Exception as e: 
        print(f"Erreur lors de la lecture de la cover de {fichier}: {e}") 
        return None 
    
def getCompressedCoverBase64(chemin_dossier, fichier, max_size=(300, 300), quality=70): 
    """Récupère, redimensionne et compresse la cover en base64.""" 
    cover_bytes = getMusicCoverBytes(chemin_dossier, fichier) 
    if not cover_bytes: 
        return None 
    try: 
        image = Image.open(io.BytesIO(cover_bytes)) 
        image.thumbnail(max_size) 
        buffer = io.BytesIO() 
        image.save(buffer, format="JPEG", quality=quality) 
        compressed_bytes = buffer.getvalue() 
        return base64.b64encode(compressed_bytes).decode('utf-8') 
    except Exception as e: 
        print(f"Erreur lors de la compression de la cover de {fichier}: {e}") 
        return None 

def setTrackList(dossier): 
    global trackList 
    trackList = [] 
    folderContent = getFolderContent(dossier) 
    for file in folderContent: 
        # Ignorer les fichiers qui ne sont pas des .mp3
        if not file.lower().endswith('.mp3'):
            continue
        
        track = { 
            'fileName': file, 
            'title': getTrackInfo(dossier, file, tagList['title']), 
            'duration': getMusicDuration(dossier, file), 
            'artist': getTrackInfo(dossier, file, tagList['artist']), 
            'album': getTrackInfo(dossier, file, tagList['album ']), 
            'cover': getCompressedCoverBase64(dossier, file), 
            'trackNumber': getTrackInfo(dossier, file, tagList['trackNumber']),
        } 
        trackList.append(track)

def getTrackList(dossier): 
    return json.dumps(trackList) 

def afficherCover(chemin_dossier, fichier): 
    """Affiche la pochette compressée.""" 
    cover_b64 = getCompressedCoverBase64(chemin_dossier, fichier) 
    if cover_b64: 
        image_data = base64.b64decode(cover_b64) 
        image = Image.open(io.BytesIO(image_data)) 
        image.show() 
    else: 
        print("Aucune cover trouvée ou erreur de lecture.")

def getFileNameFromTitle(titleName):
    """Renvoie le nom du fichier correspondant au titre donné."""
    for file in trackList:
        if file["title"] and file["title"].lower() == titleName.lower():
            return file["fileName"]
    return None


# afficherCover("Musique","Freeze Corleone - MW2.mp3")
setTrackList(music_folder)