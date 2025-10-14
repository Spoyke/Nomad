import 'dart:typed_data';

class Track {
  final String title;
  final double duration;
  final Uint8List? cover;
  const Track({required this.title, required this.duration, required this.cover});
}

List<Track> trackListe = [];
