import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'api.dart';

class Track {
  final String title;
  final String artist;
  final double duration;
  final String album;
  // final int trackNumber;
  Track({
    required this.title,
    required this.artist,
    required this.duration,
    required this.album,
    // required this.trackNumber,
  });
}

class Artist {
  final String name;
  List<Track> list;
  String? imageUrl; // URL de l’image Deezer

  Artist({required this.name, required this.list, this.imageUrl});
}

class Album {
  final String title;
  final String artist;
  final List<Track> list;
  Uint8List? cover;
  Album({required this.title, required this.artist, required this.list});
}

int indexAlbumToAsk = 0;

List<Track> trackList = [];
List<Track> sortedListByName = [];
List<Album> albumList = [];
List<Artist> artistList = [];
String currentSort = "name";

Future<void> fetchArtistImages() async {
  for (var artist in artistList) {
    final image = await fetchDeezerArtistImage(artist.name);
    artist.imageUrl = image;
  }
}

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
  // for (var album in albumList) {
  //   print(album.title);
  // }
}

void buildArtistList() {
  artistList.clear();

  for (var track in trackList) {
    var artist = artistList.firstWhere(
      (a) => a.name == track.artist,
      orElse: () {
        final newArtist = Artist(name: track.artist, list: []);
        artistList.add(newArtist);
        return newArtist;
      },
    );
    artist.list.add(track);
  }

  artistList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

Future<void> buildArtistListWithImages() async {
  buildArtistList();
  await fetchArtistImages();
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

void sortList(List<dynamic> list) {
  list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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
