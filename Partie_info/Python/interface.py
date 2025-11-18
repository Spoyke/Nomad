from datetime import datetime, timedelta, timezone 
import time
import os
import websockets
import json
import FileManager
import config
import SoundDiffuser as sd
import asyncio

# =========================
# Synchronisation des esp32
# =========================

async def sendTime():           # Envoi du temps actuel
    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    await send("esp32", "SetTime", str(now_ms))

def sendTimeOffset(delay_seconds=1):    # Envoi du temps actuel + un delai d'activation
    now = datetime.now(timezone.utc)
    offset = timedelta(seconds=delay_seconds)
    syncTime = (now + offset)
    return str(int(syncTime.timestamp() * 1000))

# ====================================
# Nettoyage de l'affichage du terminal
# ====================================

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

# ==========================================
# Hebergement & Gestion du serveur WebSocket
# ==========================================
clients = set()

async def send(target, command, content=None):
    if not clients:
        print("Aucun client connecté, message non envoyé.")
        return

    msg = {
        "target": target,
        "command": command,
    }
    if content is not None:
        msg["content"] = content

    data = json.dumps(msg)
    print(f"Envoi du message à {len(clients)} client(s) : {data}")

    # Copie du set pour éviter les erreurs si des clients se connectent/déconnectent
    for client in list(clients):
        try:
            await client.send(data)
        except Exception as e:
            print(f"Erreur d'envoi à un client : {e}")
            clients.discard(client)  # retire proprement le client défaillant

async def handleMessage(msg):
    data = json.loads(msg)
    if data.get('target') != "rPI":
        return
    match data.get('command'):
        case "start":
            await send("app","tracklist",config.tracklist)
        case "get_cover":
            album_name = data.get("content")
            filename = FileManager.getFileNameFromAlbum(album_name)
            if filename:
                cover_b64 = FileManager.getCompressedCoverBase64(config.FOLDER, filename)
                if cover_b64:
                    await send("app","Album",cover_b64)
                    print("Cover envoyée")
                else:
                    print("Aucune cover trouvée pour", filename)
            else:
                print("Album introuvable :", album_name)
        case "play":
            clear_terminal()
            music_name = data.get("content")
            if music_name:
                filename = FileManager.getFileNameFromTitle(music_name)
                if filename:
                    fichier_audio = fr"Musique/{filename}"
                    print(f"Titre reçu : {music_name}")
                    print(f"Fichier sélectionné : {fichier_audio}")

                    # Vérifie et lance la diffusion
                    if sd.verifier_fichier(fichier_audio):
                        cmd = sd.construire_commande(fichier_audio)
                        if cmd:
                            sd.diffuser(cmd)
                            await sendTime()
                            await asyncio.sleep(0.2)
                            await send("esp32", "Sync", sendTimeOffset())
                        else:
                            print("Erreur lors de la construction de la commande ffmpeg.")
                    else:
                        print("Fichier introuvable, diffusion annulée.")
                else:
                    print(f"Titre introuvable dans la liste : {music_name}")
            else:
                print("Aucun titre reçu dans la commande 'play'.")
        case "stop":
            clear_terminal()
            sd.arreter_diffusion()
        case _:
            print("Commande inconnue")

async def handler(websocket):
    clients.add(websocket)
    print("Client connecté :", websocket.remote_address)
    try:
        async for message in websocket:
            print("Message reçu du client :", json.loads(message)['target'])
            await handleMessage(message)
            for client in list(clients):
                if client != websocket:
                    try:
                        await client.send(message)
                    except websockets.exceptions.ConnectionClosed:
                        clients.remove(client)
                        print("Client retiré après déconnexion")

    except websockets.exceptions.ConnectionClosed:
        print("Client déconnecté :", websocket.remote_address)
    finally:
        clients.remove(websocket)
    
async def start_ws_server():
    server = await websockets.serve(handler, "0.0.0.0", 8765)
    print("Serveur WebSocket démarré sur ws://0.0.0.0:8765")
    return server

# ==============================
# Gestion du programme principal
# ==============================


async def interface():
    a=1

async def main():
    server = await start_ws_server()
    task = asyncio.create_task(interface())
    try:
        await server.wait_closed()
    except asyncio.CancelledError:
        pass

if __name__ == "__main__":
    os.system("sudo iwconfig wlan0 power off")  # Désactive automatiquement l'économie d'energie sur le wlan0
    os.system("sudo systemctl start icecast2")  # Lance le serveur Icecast qui heberge la musique
    asyncio.run(main())
