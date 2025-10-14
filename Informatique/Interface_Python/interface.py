import paho.mqtt.client as mqtt
import json
import file
import base64
# Paramètres MQTT
broker_address = "localhost"
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
    try : 
        data = json.loads(payload)
        match data["command"]:
            case "start":
                send(f"1{file.getTrackList('Musique')}")   
            case "set_volume":
                volume = data["value"]
                print(f"Volume mis à jour : {volume}")    
    except Exception as e:
        print("Erreur :", e)


# Création du client MQTT
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

# Connexion au broker
client.connect(broker_address, broker_port, 60)

# Démarrer la boucle pour écouter les messages
client.loop_forever()
