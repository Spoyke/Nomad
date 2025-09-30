import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MqttServerClient? _client;
  final String _broker = "192.168.1.11";
  final int _port = 1883;
  final String _topicPub = "Nomad/command";
  final String _topicSub = "Nomad/receive";
  List<String> trackList = [];
  double _currentSliderValue = 20;
  String _currentSong = "Aucune musique sélectionnée";
  double _currentPosition = 0.0;
  double _totalDuration = 0.0; // Durée totale en secondes (ex: 3 minutes)
  bool _isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initMqtt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initMqtt() {
    Future.microtask(() async {
      await connect();
    });
  }

  Future<void> connect() async {
    _client = MqttServerClient(_broker, "flutter_client");
    _client?.port = _port;
    _client?.logging(on: false);
    _client?.keepAlivePeriod = 60;
    try {
      await _client?.connect();
      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        debugPrint("Connecté au broker MQTT avec succès !");
      }
      subscribeToTopic();
      send('launch');
    } catch (e) {
      debugPrint("Erreur lors de la connexion : ${e.toString()}");
    }
  }

  Future<void> subscribeToTopic() async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint("Pas connecté au broker, pas d'envoi de msg");
      return;
    }
    _client?.subscribe(_topicSub, MqttQos.atLeastOnce);
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMes = c[0].payload as MqttPublishMessage;
      final String msg = MqttPublishPayload.bytesToStringAsString(recMes.payload.message);
      final String code = msg[0];
      final String contenu = msg.substring(1);
      switch (code) {
        case '1':
          String jsonString = contenu.replaceAll("'", '"');
          List<dynamic> dynamicList = json.decode(jsonString);
          List<String> stringList = dynamicList.cast<String>().toList();
          setState(() {
            trackList = stringList;
          });
          break;
        case '2':
          setState(() {
            _totalDuration = double.parse(contenu);
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> send(String msg) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint("Pas connecté au broker, pas d'envoi de msg");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(msg);
    _client?.publishMessage(_topicPub, MqttQos.exactlyOnce, builder.payload!);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentPosition < _totalDuration) {
          _currentPosition += 1;
        } else {
          _isPlaying = false;
          _timer?.cancel();
        }
      });
    });
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Nomad Music Player', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          centerTitle: true,
          elevation: 4,
        ),
        body: Column(
          children: [
            // Section "En cours de lecture"
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.deepPurple.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.music_note, size: 40, color: Colors.deepPurple),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _currentSong,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Slider d'avancement
                  Row(
                    children: [
                      Text(_formatDuration(_currentPosition)),
                      Expanded(
                        child: Slider(
                          value: _currentPosition,
                          min: 0,
                          max: _totalDuration,
                          activeColor: Colors.deepPurple,
                          onChanged: (double newValue) {
                            setState(() {
                              _currentPosition = newValue;
                            });
                          },
                        ),
                      ),
                      Text(_formatDuration(_totalDuration)),
                    ],
                  ),
                ],
              ),
            ),
            // Liste des musiques
            Expanded(
              child: trackList.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: trackList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.audiotrack, color: Colors.deepPurple),
                            title: Text(trackList[index]),
                            onTap: () {
                              final message = '{"command": "ask_duration", "value": "${trackList[index]}"}';
                              send(message);
                              setState(() {
                                _currentSong = trackList[index];
                                _currentPosition = 0;
                                _isPlaying = false;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            // Contrôles du lecteur
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.deepPurple.withOpacity(0.1),
              child: Column(
                children: [
                  // Slider de volume
                  Row(
                    children: [
                      Icon(Icons.volume_down, color: Colors.deepPurple),
                      Expanded(
                        child: Slider(
                          value: _currentSliderValue,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: Colors.deepPurple,
                          label: _currentSliderValue.round().toString(),
                          onChanged: (double newValue) {
                            final message = '{"command": "set_volume", "value": $newValue}';
                            send(message);
                            setState(() {
                              _currentSliderValue = newValue;
                            });
                          },
                        ),
                      ),
                      Icon(Icons.volume_up, color: Colors.deepPurple),
                    ],
                  ),
                  // Boutons de contrôle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: Icon(Icons.skip_previous, size: 32), color: Colors.deepPurple, onPressed: () {}),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple,
                        child: IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      IconButton(icon: Icon(Icons.skip_next, size: 32), color: Colors.deepPurple, onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
