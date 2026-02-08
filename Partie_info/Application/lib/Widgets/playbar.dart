import 'package:flutter/material.dart';
import '../Types/track.dart';
import '../utility.dart';
import '../Types/album.dart';

class AudioPlayerBar extends StatelessWidget {
  final Track track;
  final double currentPosition;
  final bool isPlaying;
  final double volumeValue;
  final VoidCallback onPauseResume;
  final Function(double) onPositionChanged;
  final Function(double) onVolumeChanged;

  const AudioPlayerBar({
    super.key,
    required this.track,
    required this.currentPosition,
    required this.isPlaying,
    required this.volumeValue,
    required this.onPauseResume,
    required this.onPositionChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (track.title == "Aucune musique sélectionnée") return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      color: Colors.deepPurple.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: getCoverAlbum(track),
            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Row(
            children: [
              Text(formatDuration(currentPosition)),
              Expanded(
                child: Slider(
                  value: currentPosition.clamp(0, track.duration.toDouble()),
                  min: 0,
                  max: track.duration.ceilToDouble(),
                  activeColor: Colors.deepPurple,
                  onChanged: onPositionChanged,
                ),
              ),
              Text(formatDuration(track.duration.ceilToDouble())),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, size: 32), color: Colors.deepPurple, onPressed: () {}),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple,
                child: IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                  onPressed: onPauseResume,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.skip_next, size: 32), color: Colors.deepPurple, onPressed: () {}),
              const Spacer(),
              _VolumeButton(currentVolume: volumeValue, onVolumeChanged: onVolumeChanged),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget interne pour gérer l'Overlay du volume proprement
class _VolumeButton extends StatelessWidget {
  final double currentVolume;
  final Function(double) onVolumeChanged;

  const _VolumeButton({required this.currentVolume, required this.onVolumeChanged});

  void _showVolumeOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        right: 16,
        bottom: 110,
        height: 150,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RotatedBox(
              quarterTurns: -1,
              child: Slider(
                value: currentVolume,
                min: 0,
                max: 21,
                activeColor: Colors.white,
                inactiveColor: Colors.white54,
                onChanged: (val) {
                  onVolumeChanged(val);
                  // On ne peut pas facilement redessiner l'overlay sans un Stateful,
                  // mais pour l'instant ça mettra à jour la valeur sur l'ESP32.
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_down_alt),
      color: Colors.deepPurple,
      onPressed: () => _showVolumeOverlay(context),
    );
  }
}
