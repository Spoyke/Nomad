import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchDeezerArtistImage(String artistName) async {
  final query = Uri.encodeComponent(artistName);
  final url = Uri.parse('https://api.deezer.com/search/artist?q=$query');
  print(url);
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['data'] != null && (data['data'] as List).isNotEmpty) {
      return data['data'][0]['picture_xl']; // retourne le premier artiste trouvé
    }
  }
  return null; // aucun résultat trouvé
}
