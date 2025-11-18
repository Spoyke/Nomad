import paho.mqtt.client as mqtt
import mqttClient
import json
import file
import config
import SoundDiffuser as sd
import os

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

# ==============================
# Design Pattern Command
# ==============================
class Command:
    def execute(self, data):
        raise NotImplementedError

class StartCommand(Command):
    def execute(self, data):
        tracklist = file.getTrackList(config.FOLDER)
        mqttClient.MQTTClient().publish(config.TOPIC_PUB, f"1{tracklist}")
        print("Tracklist envoyée")

class GetCoverCommand(Command):
    def execute(self, data):
        album_name = data.get("album")
        filename = file.getFileNameFromAlbum(album_name)
        if filename:
            cover_b64 = file.getCompressedCoverBase64(config.FOLDER, filename)
            if cover_b64:
                mqttClient.MQTTClient().publish(config.TOPIC_PUB, f"2{cover_b64}")
                print("Cover envoyée")
            else:
                print("Aucune cover trouvée pour", filename)
                mqttClient.MQTTClient().publish(config.TOPIC_PUB, "2")
        else:
            print("Album introuvable :", album_name)
            mqttClient.MQTTClient().publish(config.TOPIC_PUB, "2")

class SetVolumeCommand(Command):
    def execute(self, data):
        global volume
        volume = data.get("value", volume)
        print(f"Volume mis à jour : {volume}")

class Play(Command):
    def execute(self, data):
        music_name = data.get("Music")
        if music_name:
            filename = file.getFileNameFromTitle(music_name)
            if filename:
                global fichier_audio
                fichier_audio = fr"Musique\{filename}"
                sd.lancer_diffusion(fichier_audio)
                mqttClient.MQTTClient().publish("Nomad/esp32/receive", "Sync")
            else:
                print(f"Titre introuvable dans la liste : {music_name}")
        else:
            print("Aucun titre reçu dans la commande 'play'.")

class Stop(Command):
    def execute(self, data):
        mqttClient.MQTTClient().publish("Nomad/esp32/receive", "STOP")
        sd.stopper_diffusion()

# Registre des commandes
commands = {
    'start': StartCommand(),
    'get_cover': GetCoverCommand(),
    'play': Play(),
    'stop': Stop()
}

# ==============================
# Fonctions MQTT
# ==============================
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"Connecté au broker avec code {rc}")
        client.subscribe(config.TOPIC_SUB)
        print(f"Abonné au topic : {config.TOPIC_SUB}")
    else:
        print(f"Échec de connexion MQTT, code : {rc}")

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode("latin-1")
        clear_terminal()
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
# Point d’entrée
# ==============================
if __name__ == "__main__":
    mqtt_client_instance = mqttClient.MQTTClient()
    mqtt_client_instance.set_callbacks(on_connect, on_message)
    mqtt_client_instance.start_loop()
