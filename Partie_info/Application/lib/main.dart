import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'track.dart';
import 'artist.dart';
import 'album.dart';
import 'utility.dart';
import 'package:flutter/foundation.dart';
import 'package:icecast_flutter/icecast_flutter.dart';
import 'package:record/record.dart';

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
  bool isStreaming = false;
  late AudioRecorder record;
  late StreamController<List<int>> outputStream;
  late final IcecastFlutter _icecastFlutterPlugin;
  final int bitRate = 128;
  final int sampleRate = 44100;
  final int numChannels = 2;

  String url = 'ws://10.42.0.1:8765';
  late WebSocketChannel _channel;
  double _currentSliderValue = 6;
  double _currentPosition = 0.0;
  bool _isPlaying = false;
  Timer? _timer;
  Track _currentTrack = Track(duration: 0, title: "Aucune musique sélectionnée", artist: "", album: "");

  Widget _getCoverAlbum(Track track) {
    return getCoverByName(track.title) != null
        ? Image.memory(getCoverByName(track.title)!, width: 32, height: 32)
        : Icon(Icons.audiotrack, color: Colors.deepPurple);
  }

  @override
  void initState() {
    super.initState();
    trackList = [];
    _connectWS();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTrackListGetter(String message) async {
    try {
      List data = jsonDecode(message)['content'];
      setState(() {
        trackList = data
            .map((e) => Track(title: e['title'], artist: e['artist'], duration: e['duration'], album: e['album']))
            .toList();
        sortList(trackList);
        buildAlbumList();
      });
      _sendWS("rPI", "get_cover", albumList.first.title);
    } catch (e) {
      debugPrint("Reception Trackliste erronnée : $e");
    }
  }

  void _handleCoverGetter(String message) {
    try {
      String coverString = jsonDecode(message)['content'];
      final Uint8List bytes = base64Decode(coverString);
      setState(() {
        albumList[indexAlbumToAsk].cover = bytes;
      });

      debugPrint("Cover reçue pour : ${albumList[indexAlbumToAsk].title}");
      indexAlbumToAsk++;
      if (indexAlbumToAsk < albumList.length) {
        debugPrint("Demande cover pour : ${albumList[indexAlbumToAsk].title}");
        _sendWS("rPI", "get_cover", albumList[indexAlbumToAsk].title);
      } else {
        debugPrint("Toutes les covers ont été demandées");
      }
    } catch (e) {}
  }

  void _sendWS(String target, String command, [String? content]) {
    Map<String, String> msg = {};
    msg['target'] = target;
    msg['command'] = command;
    if (content != null) msg['content'] = content;
    _channel.sink.add(json.encode(msg));
  }

  void _connectWS() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel.ready;
      debugPrint('Connexion WebSocket établie');
      _sendWS('rPI', 'start');
      _channel.stream.listen(
        (message) async {
          String command = jsonDecode(message)['command'];
          switch (command) {
            case "tracklist":
              _handleTrackListGetter(message);
              break;
            case "Album":
              try {
                _handleCoverGetter(message);
              } catch (e) {
                debugPrint("Erreur réception cover: $e");
              }
              break;
          }
        },
        onDone: () {
          debugPrint('Connexion fermée');
          _onDisconnected();
        },
        onError: (error) {
          debugPrint('Erreur: $error');
          _onDisconnected();
        },
      );
    } catch (e) {
      debugPrint("Erreur WebSocket: $e");
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _timer?.cancel(); // Arrêter le minuteur de lecture
    setState(() {
      _isPlaying = false;
      _currentTrack = Track(duration: 1, title: "DÉCONNECTÉ - Veuillez vérifier votre réseau.", artist: "", album: "");
      _currentPosition = 0;
    });
    Future.delayed(Duration(seconds: 1), () {
      debugPrint("Tentative de reconnexion...");
      _connectWS();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentPosition < _currentTrack.duration) {
          _currentPosition += 1;
        } else {
          _isPlaying = false;
          _timer?.cancel();
        }
      });
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
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
                    play(_currentTrack);
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumView(cover: album.cover!)));
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

  void play(Track track) {
    _sendWS("rPI", "play", track.title);
    _startTimer();
    setState(() {
      _isPlaying = true;
    });
  }

  void pause() {
    _sendWS("esp32", "Stop");
    _sendWS("rPI", "stop", "");
    _stopTimer();
    setState(() {
      _isPlaying = false;
    });
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
                  print("Appui sur le btn de réglage");
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
                            max: _currentTrack.duration.ceil().toDouble(),
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
                                onPressed: pause,
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
                                            max: 21,
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white54,
                                            onChanged: (value) {
                                              setState(() {
                                                _currentSliderValue = value;
                                              });
                                              _sendWS("esp32", "Volume", _currentSliderValue.toInt().toString());
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
