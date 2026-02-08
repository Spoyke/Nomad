import 'track.dart';
import 'dart:typed_data';
import '../utility.dart';
import 'package:flutter/material.dart';

class Album {
  final String title;
  final String artist;
  final List<Track> list;
  Uint8List? cover;
  Album({required this.title, required this.artist, required this.list});
}

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

Widget getCoverAlbum(Track track) {
  return getCoverByName(track.title) != null
      ? Image.memory(getCoverByName(track.title)!, width: 32, height: 32)
      : Icon(Icons.audiotrack, color: Colors.deepPurple);
}

List<Album> albumList = [];
int indexAlbumToAsk = 0;

void buildAlbumList() {
  albumList.clear();
  for (var track in trackList) {
    var album = albumList.firstWhere(
      (a) => a.title == track.album && a.artist == track.artist,
      orElse: () {
        final newAlbum = Album(title: track.album, artist: track.artist, list: []);
        albumList.add(newAlbum);
        return newAlbum;
      },
    );
    album.list.add(track);
  }
  sortList(albumList);
}
