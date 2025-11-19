import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'track.dart';
import 'album.dart';

Uint8List? getCoverByName(String trackTitle) {
  final track = trackList.firstWhere(
    (t) => t.title == trackTitle,
    orElse: () => Track(
      title: '',
      artist: '',
      duration: 0,
      album: '',
      // trackNumber: 0
    ),
  );
  if (track.title.isEmpty) return null;
  final album = albumList.firstWhere(
    (a) => a.title == track.album && a.artist == track.artist,
    orElse: () => Album(title: '', artist: '', list: []),
  );
  if (album.title.isEmpty) return null;
  if (album.cover != null) return album.cover;
  return null;
}

class AlbumView extends StatelessWidget {
  final Uint8List cover;
  const AlbumView({super.key, required this.cover});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AlbumName"), backgroundColor: Colors.deepPurple, centerTitle: true),
      body: Center(
        child: Image.memory(cover, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }
}
