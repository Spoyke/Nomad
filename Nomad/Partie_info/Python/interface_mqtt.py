import paho.mqtt.client as mqtt
import json
import file
# Paramètres MQTT
broker_address = "192.168.1.11"
broker_port = 1883
topic_pub = "test/out"
topic_command = "Nomad/command"
volume = 15

def on_connect(client, userdata, flags, rc):
    client.subscribe(topic_command)
    print(f"Écoute sur le topic : {topic_command}")

def send(msg):
    topic = "Nomad/receive"
    client.publish(topic, msg)


def on_message(client, userdata, msg):
    global volume
    payload = msg.payload.decode()
    print(f"Message reçu sur {msg.topic} : {payload}")
    if payload == 'launch':
        send(f"1{file.getFolderContent('Musique')}")
    else:        
        data = json.loads(payload)
        if data["command"] == "set_volume":
            volume = data["value"]
            print(f"Volume mis à jour : {volume}")
        if data["command"] == "ask_duration":
            track = data["value"]
            duration = file.getMusicDuration("Musique", track)
        send(f"2{duration}")

# Création du client MQTT
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

# Connexion au broker
client.connect(broker_address, broker_port, 60)

# Démarrer la boucle pour écouter les messages
client.loop_forever()
