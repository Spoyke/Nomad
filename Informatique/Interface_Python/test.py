# import socket

# host = "test.mosquitto.org"
# ports = [1883, 8883, 8080, 8081, 443, 80]

# def test_port(host, port, timeout=3):
#     try:
#         with socket.create_connection((host, port), timeout=timeout):
#             print(f"[OUVERT]  Port {port} accessible sur {host}")
#     except socket.timeout:
#         print(f"[TIMEOUT] Port {port} ne répond pas (bloqué ou filtré)")
#     except Exception as e:
#         print(f"[FERMÉ]   Port {port} inaccessible ({e})")

# print(f"Test des ports MQTT sur {host}...\n")
# for port in ports:
#     test_port(host, port)

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
