import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
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
  final String esp32Ip = "10.42.0.1";
  final int port = 4953; // Port Snapcast TCP (remplace 1780 pour l'audio)
  late AudioSocketService _socketService;

  // --- ÉTAT AUDIO / MICRO ---
  bool isStreaming = false;
  String statusLogs = "Prêt à diffuser";
  Socket? _tcpSocket; // Changement de UDP vers TCP pour Snapcast
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _audioSubscription;
  late AudioRecorder _audioRecorder;
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
    _audioRecorder = AudioRecorder(); // Initialisation ici
    _initRecorder();
    _initSocketService();
  }

  void _initSocketService() {
    _socketService = AudioSocketService(
      url: 'ws://10.42.0.1:8765',
      onTrackListReceived: (tracks) {
        setState(() {
          trackList = tracks;
          sortList(trackList);
          buildAlbumList();
        });
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
    await _recorder.initialize(sampleRate: 16000); // Assure-toi que Snapserver accepte le 16kHz
    debugPrint("Recorder initialisé");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    _tcpSocket?.destroy();
    _socketService.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // --- LOGIQUE DES COVERS ---
  void _handleCoverUpdate(String base64Data) {
    try {
      final Uint8List bytes = base64Decode(base64Data);
      setState(() {
        albumList[indexAlbumToAsk].cover = bytes;
      });

      indexAlbumToAsk++;
      if (indexAlbumToAsk < albumList.length) {
        _socketService.send("rPI", "get_cover", albumList[indexAlbumToAsk].title);
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
    Future.delayed(const Duration(seconds: 2), () => _socketService.connect());
  }

  void _startTimer() {
    _stopTimer();
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

  // --- STREAMING MICRO (TCP / SNAPCAST) ---
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  Future<void> startStreaming() async {
    try {
      await _stopAudioResources();

      // 1. Vérifier les permissions
      if (await _audioRecorder.hasPermission() == false) return;

      // 2. Connexion Socket
      _tcpSocket = await Socket.connect(esp32Ip, port);
      _tcpSocket!.setOption(SocketOption.tcpNoDelay, true);

      // 3. Configuration de l'enregistrement
      // On demande explicitement du PCM 16 bits, 44.1kHz, Mono
      const config = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 44100, numChannels: 2);

      // 4. Démarrage du flux
      final stream = await _audioRecorder.startStream(config);

      _audioStreamSubscription = stream.listen((data) {
        if (_tcpSocket != null) {
          // Avec 'record', les données sont déjà en Uint8List (PCM 16-bit)
          // Pas besoin de conversion manuelle compliquée !
          _tcpSocket!.add(data);
        }
      });

      setState(() {
        isStreaming = true;
        statusLogs = "🔴 Diffusion active (record)";
      });
    } catch (e) {
      debugPrint("Erreur : $e");
      stopStreaming();
    }
  }

  Future<void> _stopAudioResources() async {
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    _tcpSocket?.destroy();
    _tcpSocket = null;
    setState(() => isStreaming = false);
  }

  Future<void> stopStreaming() async {
    await _stopAudioResources();
    if (mounted) {
      setState(() {
        statusLogs = "Arrêté.";
      });
    }
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
                      onVolumeChanged: (val) => _socketService.send("rPI", "VolumeMic", val.toInt().toString()),
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
