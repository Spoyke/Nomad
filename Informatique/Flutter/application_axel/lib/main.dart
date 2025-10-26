import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'classes.dart';

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
  final String _broker = "test.mosquitto.org";
  final int _port = 1883;
  final String _topicPub = "Nomad/command";
  final String _topicSub = "Nomad/receive";
  double _currentSliderValue = 20;
  double _currentPosition = 0.0;
  final double _totalDuration = 0.0; // Durée totale en secondes (ex: 3 minutes)
  bool _isPlaying = false;
  Timer? _timer;
  Track _currentTrack = Track(
    duration: 0,
    title: "Aucune musique sélectionnée",
    artist: "",
    album: "",
    // trackNumber: 1
  );

  Uint8List? imageBytes;

  Widget _getCoverAlbum(Track track) => getCoverByName(track.title) != null
      ? Image.memory(getCoverByName(track.title)!, width: 32, height: 32)
      : Icon(Icons.audiotrack, color: Colors.deepPurple);

  Future<void> send(String msg) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint("Pas connecté au broker, pas d'envoi de msg");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(msg);
    _client?.publishMessage(_topicPub, MqttQos.exactlyOnce, builder.payload!);
  }

  void sendCommand(String command, [Map<String, dynamic>? data]) {
    final payload = jsonEncode({"command": command, ...?data});
    send(payload);
  }

  @override
  void initState() {
    super.initState();
    trackList = [];
    Future.delayed(Duration.zero, () async {
      await connect();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _handleTrackListGetter(String content) async {
    try {
      final List data = jsonDecode(content);
      setState(() {
        trackList = data
            .map((e) => Track(title: e['title'], artist: e['artist'], duration: e['duration'], album: e['album']))
            .toList();
        sortList(trackList);
        buildAlbumList();
      });

      await buildArtistListWithImages(); // <-- télécharge aussi les images Deezer
      for (final artist in artistList) {
        if (artist.imageUrl != null) {
          precacheImage(NetworkImage(artist.imageUrl!), context);
        }
      }
      send(jsonEncode({"command": "get_cover", "album": albumList.first.title}));
    } catch (e) {
      debugPrint("Erreur parsing liste: $e");
    }
  }

  void _handleCoverGetter(String content) {
    try {
      final bytes = base64Decode(content);
      setState(() {
        albumList[indexAlbumToAsk].cover = bytes;
      });

      debugPrint("Cover reçue pour : ${albumList[indexAlbumToAsk].title}");
      indexAlbumToAsk++;
      if (indexAlbumToAsk < albumList.length) {
        debugPrint("Demande cover pour : ${albumList[indexAlbumToAsk].title}");
        send(jsonEncode({"command": "get_cover", "album": albumList[indexAlbumToAsk].title}));
      } else {
        debugPrint("Toutes les covers ont été demandées");
      }
    } catch (e) {
      debugPrint("Erreur réception cover: $e");
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
      debugPrint("Code de reception : $code");
      final String contenu = msg.substring(1);
      switch (code) {
        case '1':
          _handleTrackListGetter(contenu);
          break;
        case '2':
          _handleCoverGetter(contenu);
          break;
        default:
          break;
      }
    });
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

  Widget _showByTrackName() {
    return trackList.isEmpty
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: trackList.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: _getCoverAlbum(trackList[index]),
                  title: Text(trackList[index].title),
                  subtitle: Text(trackList[index].artist),
                  trailing: Text(_formatDuration(trackList[index].duration.ceilToDouble())),
                  onTap: () {
                    setState(() {
                      _currentTrack = trackList[index];
                      _currentPosition = 0;
                      _isPlaying = false;
                    });
                  },
                ),
              );
            },
          );
  }

  Widget _showByAlbumName() {
    return albumList.isEmpty
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: albumList.length,
            itemBuilder: (context, index) {
              final album = albumList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyWidget(cover: album.cover!)));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: album.cover != null
                            ? Image.memory(album.cover!, width: double.infinity, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.album, size: 60, color: Colors.grey[700]),
                              ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _showByArtistName() {
    return artistList.isEmpty
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: artistList.length,
            itemBuilder: (context, index) {
              final Artist artist = artistList[index];
              return GestureDetector(
                onTap: () {
                  // setState(() {
                  //   indexAlbumToAsk = index;
                  //   trackList = artist.list;
                  //   currentSort = "name";
                  // });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: artist.imageUrl != null
                            ? Image.network(artist.imageUrl!, width: 300, height: 300)
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.person, size: 60, color: Colors.grey[700]),
                              ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Nomad Audio Controller', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.deepPurple,
            centerTitle: true,
            elevation: 4,
            bottom: TabBar(
              labelColor: Colors.white,
              tabs: [
                Tab(text: "Pistes"),
                Tab(text: "Albums"),
                Tab(text: "Artistes"),
              ],
            ),
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
                child: TabBarView(
                  children: [
                    _showByTrackName(), // Affichage par piste
                    _showByAlbumName(), // Affichage par album
                    _showByArtistName(),
                  ],
                ),
              ),
              // Gestion de la lecture
              Container(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                color: Colors.deepPurple.withOpacity(0.1),
                child: Column(
                  children: [
                    _currentTrack.title != "Aucune musique sélectionnée"
                        ? ListTile(
                            leading: _getCoverAlbum(_currentTrack),
                            title: Text(_currentTrack.title),
                            subtitle: Text(_currentTrack.artist),
                          )
                        : SizedBox(height: 0),
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
                        Text(_formatDuration(_currentTrack.duration.ceilToDouble())),
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
                            IconButton(
                              icon: Icon(Icons.skip_next, size: 32),
                              color: Colors.deepPurple,
                              onPressed: () {},
                            ),
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
                                late OverlayEntry entry;

                                entry = OverlayEntry(
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
                                          quarterTurns: -1, // slider vertical
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

                                overlay.insert(entry);

                                // Retire l’overlay quand on reclique ou sort
                                Future.delayed(Duration(seconds: 5), () {
                                  entry.remove();
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
      ),
    );
  }
}
