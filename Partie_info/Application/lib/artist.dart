import 'track.dart';
import 'api.dart';

class Artist {
  final String name;
  List<Track> list;
  String? imageUrl; // URL de l’image Deezer

  Artist({required this.name, required this.list, this.imageUrl});
}

List<Artist> artistList = [];

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

Future<void> fetchArtistImages() async {
  for (var artist in artistList) {
    final image = await fetchDeezerArtistImage(artist.name);
    artist.imageUrl = image;
  }
}

Future<void> buildArtistListWithImages() async {
  buildArtistList();
  await fetchArtistImages();
}
