import asyncio
import websockets

async def send_message():
    uri = "ws://127.0.0.1:8765"  # IP de ton serveur WebSocket
    async with websockets.connect(uri) as websocket:
        msg = '{"command": "START"}'
        await websocket.send(msg)
        print(f"Message envoyé : {msg}")

asyncio.run(send_message())
