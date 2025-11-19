import asyncio
import websockets
import json

clients = set()

async def handler(websocket):
    clients.add(websocket)
    print("Client connecté :", websocket.remote_address)
    try:
        async for message in websocket:
            print("Message reçu du client :", json.loads(message)['target'])
            for client in clients:
                if client != websocket:
                    await client.send(message)
    except websockets.exceptions.ConnectionClosed:
        print("Client déconnecté :", websocket.remote_address)
    finally:
        clients.remove(websocket)

async def start_ws_server():
    server = await websockets.serve(handler, "0.0.0.0", 8765)
    print("Serveur WebSocket démarré sur ws://0.0.0.0:8765")
    return server