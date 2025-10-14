import 'package:application/classes.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
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
  double _currentSliderValue = 20;
  String _currentSong = "Aucune musique sélectionnée";
  double _currentPosition = 0.0;
  double _totalDuration = 0.0; // Durée totale en secondes (ex: 3 minutes)
  bool _isPlaying = false;
  Timer? _timer;
  Track _currentTrack = Track(duration: 0, title: "Aucune musique sélectionnée", cover: null);

  Uint8List? imageBytes;
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
      send(jsonEncode({"command": "start"}));
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
          try {
            List<dynamic>? jsonData = jsonDecode(contenu);
            setState(() {
              for (var data in jsonData!) {
                trackListe.add(
                  Track(
                    title: data['title'],
                    duration: data['duration'],
                    cover: data['cover'] != null ? base64Decode(data['cover']) : null,
                  ),
                );
              }
            });
          } catch (e) {
            print(e);
          }
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
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                send(jsonEncode({"command": "askJson"}));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: trackListe.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: trackListe.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: trackListe[index].cover != null
                                ? Image.memory(trackListe[index].cover!, width: 32, height: 32)
                                : Icon(Icons.audiotrack, color: Colors.deepPurple),
                            title: Text(trackListe[index].title),
                            trailing: Text(_formatDuration(trackListe[index].duration.ceilToDouble())),
                            onTap: () {
                              // final message = '{"command": "ask_duration", "value": "${trackListe[index].title}"}';
                              // send(message);
                              setState(() {
                                _currentTrack = trackListe[index];
                                _currentSong = trackListe[index].title;
                                _currentPosition = 0;
                                _isPlaying = false;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.deepPurple.withOpacity(0.1),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          _currentTrack.cover == null
                              ? Icon(Icons.music_note, size: 40, color: Colors.deepPurple)
                              : Image.memory(_currentTrack.cover!, height: 52),
                          SizedBox(width: 16),
                        ],
                      ),
                      Text(
                        _currentTrack.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous, size: 32),
                            color: Colors.deepPurple,
                            onPressed: () {},
                          ),
                          SizedBox(width: 16),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.deepPurple,
                            child: IconButton(
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                              onPressed: _togglePlayPause,
                            ),
                          ),
                          SizedBox(width: 16),
                          IconButton(icon: Icon(Icons.skip_next, size: 32), color: Colors.deepPurple, onPressed: () {}),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.volume_down_alt),
                            color: Colors.deepPurple,
                            onPressed: () {
                              final overlay = Overlay.of(context);
                              OverlayEntry entry = OverlayEntry(
                                builder: (context) => Positioned(
                                  right: 16,
                                  bottom: 100,
                                  height: 150,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: RotatedBox(
                                        quarterTurns: -1, // -1 pour vertical de bas en haut
                                        child: Slider(
                                          value: _currentSliderValue,
                                          min: 0,
                                          max: 100,
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white54,
                                          onChanged: (value) {
                                            setState(() {
                                              _currentSliderValue = value;
                                            });
                                            send('{"command": "set_volume", "value": $value}');
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              overlay?.insert(entry);

                              Future.delayed(Duration(seconds: 3), () {
                                entry?.remove();
                              });
                            },
                          ),
                        ),
                      ),
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
