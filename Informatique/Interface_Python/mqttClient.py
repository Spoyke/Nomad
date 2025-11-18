# mqtt_client.py
"""
Contient la classe Singleton pour le client MQTT.
"""
import paho.mqtt.client as mqtt
import config

class MQTTClient:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.client = mqtt.Client()
        return cls._instance

    def set_callbacks(self, on_connect_func, on_message_func):
        """Assigne les fonctions de callback au client."""
        self.client.on_connect = on_connect_func
        self.client.on_message = on_message_func

    def start_loop(self):
        """Se connecte au broker et démarre la boucle."""
        try:
            self.client.connect(config.BROKER_ADDRESS, config.BROKER_PORT, 60)
            print(f"Connecté au broker : {config.BROKER_ADDRESS}")
            self.client.loop_forever()
        except Exception as e:
            print(f"Erreur de connexion MQTT : {e}")

    def publish(self,topic, msg):
        """Publie un message sur le topic de publication."""
        self.client.publish(topic, msg)