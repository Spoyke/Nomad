import 'package:flutter/material.dart';
import '../Types/track.dart';
import '../Types/album.dart';
import '../utility.dart';

class TrackViewer extends StatelessWidget {
  final List<Track> tracks;
  final Function(Track) onTrackTap; // Callback pour gérer le clic

  const TrackViewer({super.key, required this.tracks, required this.onTrackTap});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: getCoverAlbum(track),
            title: Text(track.title),
            subtitle: Text(track.artist),
            trailing: Text(formatDuration(track.duration.ceilToDouble())),
            onTap: () => onTrackTap(track), // On appelle la fonction passée en paramètre
          ),
        );
      },
    );
  }
}
