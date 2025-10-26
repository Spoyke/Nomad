import paho.mqtt.client as mqtt
import json
import file

# ==============================
# Variables & Constantes
# ==============================
BROKER_ADDRESS = "test.mosquitto.org"
BROKER_PORT = 1883
TOPIC_SUB = "Nomad/command"
TOPIC_PUB = "Nomad/receive"
FOLDER = "Musique"
volume = 15

# ==============================
# Design Pattern Command
# ==============================
class Command:
    def execute(self, data):
        raise NotImplementedError

class StartCommand(Command):
    def execute(self,data):
        tracklis = file.getTrackList(FOLDER)
        MQTTClient().publish(f"1{tracklis}")
        print("Tracklist envoyée")

class GetCoverCommand(Command):
    def execute(self,data):
        album_name = data.get("album")
        filename = file.getFileNameFromAlbum(album_name)
        if filename:
            cover_b64 = file.getCompressedCoverBase64(FOLDER, filename)
            if cover_b64:
                MQTTClient().publish(f"2{cover_b64}")
                print("Cover envoyée")
            else:
                print("Aucune cover trouvée pour", filename)
                MQTTClient().publish("2")
        else:
            print("Album introuvable :", album_name)
            MQTTClient().publish("2")

class SetVolumeCommand(Command):
    def execute(self, data):
        global volume
        volume = data.get("value", volume)
        print(f"Volume mis à jour : {volume}")
        
# Registre des commandes
commands = {
    'start' : StartCommand(),
    'get_cover' : GetCoverCommand()
}

# ==============================
# SINGLETON POUR CLIENT MQTT
# ==============================
class MQTTClient:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.client = mqtt.Client()
        return cls._instance

    def connect(self):
        self.client.on_connect = on_connect
        self.client.on_message = on_message
        self.client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
        print(f"Connecté au broker : {BROKER_ADDRESS}")
        self.client.loop_forever()

    def publish(self, msg):
        self.client.publish(TOPIC_PUB, msg)

# ==============================
# Fonctions du MQTT
# ==============================
def on_connect(client, userdata, flags, rc):
    client.subscribe(TOPIC_SUB)
    print(f"Abonné au topic : {TOPIC_SUB}")

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        print(f"Message reçu sur {msg.topic} : {payload}")
        data = json.loads(payload)

        command_name = data.get("command")
        command = commands.get(command_name)

        if command:
            command.execute(data)
        else:
            print("Commande inconnue :", command_name)

    except Exception as e:
        print("Erreur lors du traitement du message :", e)

# ==============================
# POINT D’ENTRÉE
# ==============================
if __name__ == "__main__":
    mqtt_client = MQTTClient()
    mqtt_client.connect()