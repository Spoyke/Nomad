import 'track.dart';
import 'dart:typed_data';
import 'utility.dart';

class Album {
  final String title;
  final String artist;
  final List<Track> list;
  Uint8List? cover;
  Album({required this.title, required this.artist, required this.list});
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
