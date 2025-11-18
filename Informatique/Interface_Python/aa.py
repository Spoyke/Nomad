import paho.mqtt.client as mqtt

BROKER = "test.mosquitto.org"
PORT = 8080
TOPIC = "Nomad/esp32/receive"

client = mqtt.Client(transport="websockets")
client.connect(BROKER, PORT, 60)

message = "salut"
client.publish(TOPIC, message)
print(f"Message envoyé : {message}")

client.disconnect()
