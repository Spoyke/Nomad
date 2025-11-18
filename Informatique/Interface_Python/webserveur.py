import asyncio
import websockets

# Liste des clients connectés
clients = set()

async def handler(websocket):
    # Ajouter le client à la liste
    clients.add(websocket)
    try:
        async for message in websocket:
            print(f"Message reçu : {message}")
            # Relayer le message à tous les autres clients
            for client in clients:
                if client != websocket:
                    await client.send(message)
    except websockets.exceptions.ConnectionClosed:
        print("Client déconnecté")
    finally:
        clients.remove(websocket)

async def main():
    # Serveur sur le port 8765 (HTTP WebSocket simple)
    async with websockets.serve(handler, "0.0.0.0", 8765):
        print("Serveur WebSocket démarré sur ws://0.0.0.0:8765")
        await asyncio.Future()  # boucle infinie

asyncio.run(main())
