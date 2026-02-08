import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'Types/track.dart';
import 'Types/album.dart';
import 'utility.dart';
import 'websocket.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';

import 'Widgets/trackviewer.dart';
import 'Widgets/albumviewer.dart';
import 'Widgets/microcontrol.dart';
import 'Widgets/playbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // --- CONFIGURATION & RÉSEAU ---
  final String esp32Ip = "10.42.0.188";
  final int port = 12345;
  late AudioSocketService _socketService;

  // --- ÉTAT AUDIO / MICRO ---
  bool isStreaming = false;
  String statusLogs = "Prêt à diffuser en UDP";
  RawDatagramSocket? _udpSocket;
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _audioSubscription;

  // --- ÉTAT LECTEUR ---
  double _currentSliderValue = 6;
  double _currentPosition = 0.0;
  bool _isPlaying = false;
  Timer? _timer;
  Track _currentTrack = Track(duration: 0, title: "Aucune musique sélectionnée", artist: "", album: "");

  @override
  void initState() {
    super.initState();
    trackList = [];
    _initRecorder();
    _initSocketService();
  }

  // Initialise le service WebSocket et ses callbacks
  void _initSocketService() {
    _socketService = AudioSocketService(
      url: 'ws://10.42.0.1:8765',
      onTrackListReceived: (tracks) {
        setState(() {
          trackList = tracks;
          sortList(trackList);
          buildAlbumList();
        });
        // Lancement de la récupération des pochettes
        if (albumList.isNotEmpty) {
          _socketService.send("rPI", "get_cover", albumList.first.title);
        }
      },
      onCoverReceived: (albumTitle, base64Data) {
        _handleCoverUpdate(base64Data);
      },
      onDisconnected: _onDisconnected,
    );
    _socketService.connect();
  }

  Future<void> _initRecorder() async {
    await _recorder.initialize(sampleRate: 16000);
    debugPrint("Recorder initialisé");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  // --- LOGIQUE DES COVERS ---
  void _handleCoverUpdate(String base64Data) {
    try {
      final Uint8List bytes = base64Decode(base64Data);
      setState(() {
        albumList[indexAlbumToAsk].cover = bytes;
      });

      debugPrint("Cover reçue pour : ${albumList[indexAlbumToAsk].title}");

      indexAlbumToAsk++;
      if (indexAlbumToAsk < albumList.length) {
        _socketService.send("rPI", "get_cover", albumList[indexAlbumToAsk].title);
      } else {
        debugPrint("Toutes les covers chargées.");
      }
    } catch (e) {
      debugPrint("Erreur décodage cover: $e");
    }
  }

  // --- CONTRÔLE LECTURE ---
  void play(Track track) {
    _socketService.send("rPI", "play", track.title);
    _startTimer();
    setState(() {
      _currentTrack = track;
      _currentPosition = 0;
      _isPlaying = true;
    });
  }

  void pause() {
    _socketService.send("esp32", "Stop");
    _socketService.send("rPI", "stop", "");
    _stopTimer();
    setState(() => _isPlaying = false);
  }

  void _onDisconnected() {
    _stopTimer();
    setState(() {
      _isPlaying = false;
      _currentTrack = Track(duration: 1, title: "DÉCONNECTÉ - Reconnexion...", artist: "", album: "");
      _currentPosition = 0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      debugPrint("Tentative de reconnexion...");
      _socketService.connect();
    });
  }

  // --- GESTION DU TIMER ---
  void _startTimer() {
    _stopTimer(); // Sécurité
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _timer?.cancel();
    _timer = null;
  }

  // --- STREAMING MICRO (UDP) ---
  Future<void> startStreaming() async {
    pause();
    if (await Permission.microphone.request().isDenied) {
      setState(() => statusLogs = "Micro refusé");
      return;
    }
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.send(utf8.encode("salut"), InternetAddress(esp32Ip), port);
      setState(() {
        statusLogs = "🔴 Diffusion active";
        isStreaming = true;
      });

      // --- SUPPRESSION DU MESSAGE "SALUT" (Il pollue le flux audio) ---

      // Code bon pour le python
      _audioSubscription = _recorder.audioStream.listen((data) {
        if (_udpSocket != null && isStreaming) {
          // Si data[i] est entre 0 et 255, c'est du Uint8.
          // On l'envoie directement sans boucle for coûteuse.
          _udpSocket!.send(Uint8List.fromList(data.map((e) => e.toInt()).toList()), InternetAddress(esp32Ip), port);
        }
      });

      // _audioSubscription = _recorder.audioStream.listen((data) async {
      //   if (_udpSocket != null && isStreaming) {
      //     try {
      //       int lengthInBytes = data.length;
      //       int validLength = lengthInBytes - (lengthInBytes % 4);
      //       if (validLength == 0) return;

      //       Float32List samples = data.buffer.asFloat32List(data.offsetInBytes, validLength ~/ 4);
      //       final byteData = ByteData(samples.length * 4); // ✅ stéréo

      //       for (int i = 0; i < samples.length; i++) {
      //         double s = samples[i];
      //         if (!s.isFinite) s = 0.0;

      //         int sampleInt16 = (s * 25000).toInt().clamp(-32768, 32767);

      //         // Left
      //         byteData.setInt16(i * 4, sampleInt16, Endian.little);
      //         // Right
      //         byteData.setInt16(i * 4 + 2, sampleInt16, Endian.little);
      //       }

      //       Uint8List fullBuffer = byteData.buffer.asUint8List();
      //       int chunkSize = 1024;

      //       for (int i = 0; i < fullBuffer.length; i += chunkSize) {
      //         int end = (i + chunkSize < fullBuffer.length) ? i + chunkSize : fullBuffer.length;
      //         _udpSocket!.send(Uint8List.sublistView(fullBuffer, i, end), InternetAddress(esp32Ip), port);

      //         // Délai pour l'ESP32
      //         // await Future.delayed(const Duration(milliseconds: 2));
      //       }
      //     } catch (e) {
      //       debugPrint("Erreur lors du traitement audio : $e");
      //     }
      //   }
      // });

      await _recorder.start();
    } catch (e) {
      stopStreaming();
      setState(() => statusLogs = "Erreur: $e");
    }
  }

  Future<void> stopStreaming() async {
    await _audioSubscription?.cancel();
    await _recorder.stop();
    _udpSocket?.close();
    _udpSocket = null;

    setState(() {
      isStreaming = false;
      statusLogs = "Arrêté.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Nomad Audio Controller', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.deepPurple,
            centerTitle: true,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: "Pistes"),
                Tab(text: "Albums"),
                Tab(text: "Micro"),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    TrackViewer(tracks: trackList, onTrackTap: (track) => play(track)),
                    AlbumGridView(albums: albumList, onAlbumTap: (album) {}),
                    MicroControlView(
                      isStreaming: isStreaming,
                      statusLogs: statusLogs,
                      onToggleStreaming: isStreaming ? stopStreaming : startStreaming,
                    ),
                  ],
                ),
              ),
              AudioPlayerBar(
                track: _currentTrack,
                currentPosition: _currentPosition,
                isPlaying: _isPlaying,
                volumeValue: _currentSliderValue,
                onPauseResume: pause,
                onPositionChanged: (val) => setState(() => _currentPosition = val),
                onVolumeChanged: (val) {
                  setState(() => _currentSliderValue = val);
                  _socketService.send("esp32", "Volume", val.toInt().toString());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
