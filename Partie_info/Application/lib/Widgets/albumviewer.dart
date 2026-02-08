import 'package:flutter/material.dart';
import '../Types/album.dart'; // Vérifie que le chemin vers ta classe Album est correct

class AlbumGridView extends StatelessWidget {
  final List<Album> albums;
  final Function(Album) onAlbumTap;

  const AlbumGridView({super.key, required this.albums, required this.onAlbumTap});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () => onAlbumTap(album),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.cover != null
                      ? Image.memory(album.cover!, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.album, size: 60, color: Colors.grey[700]),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
