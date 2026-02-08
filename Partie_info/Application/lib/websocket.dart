import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'Types/track.dart';
import 'package:flutter/material.dart';

class AudioSocketService {
  WebSocketChannel? _channel;
  final String url;

  // Callbacks pour communiquer avec le main.dart
  final Function(List<Track>) onTrackListReceived;
  final Function(String, String) onCoverReceived; // albumTitle, base64Data
  final VoidCallback onDisconnected;

  AudioSocketService({
    required this.url,
    required this.onTrackListReceived,
    required this.onCoverReceived,
    required this.onDisconnected,
  });

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _channel!.stream.listen(
        (message) => _parseMessage(message),
        onDone: onDisconnected,
        onError: (_) => onDisconnected(),
      );

      // Message d'initialisation
      send("rPI", "start");
    } catch (e) {
      onDisconnected();
    }
  }

  void _parseMessage(String message) {
    final Map<String, dynamic> data = jsonDecode(message);
    final String command = data['command'];

    switch (command) {
      case "tracklist":
        List content = data['content'];
        List<Track> tracks = content
            .map((e) => Track(title: e['title'], artist: e['artist'], duration: e['duration'], album: e['album']))
            .toList();
        onTrackListReceived(tracks);
        break;

      case "Album":
        // On suppose que ton JSON contient le titre de l'album pour savoir lequel mettre à jour
        onCoverReceived(data['album_title'] ?? "", data['content']);
        break;
    }
  }

  void send(String target, String command, [String? content]) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'target': target, 'command': command, if (content != null) 'content': content}));
    }
  }

  void dispose() {
    _channel?.sink.close();
  }
}
