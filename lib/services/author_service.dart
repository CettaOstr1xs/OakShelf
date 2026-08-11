import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/author.dart';

class AuthorService {
  Future<Author?> fetchAuthorInfo(String authorName) async {
    if (authorName.trim().isEmpty) return null;

    try {
      // 1. Search author to get the OL key
      final searchUrl = Uri.parse(
        'https://openlibrary.org/search/authors.json?q=${Uri.encodeComponent(authorName)}',
      );
      final searchRes = await http
          .get(searchUrl)
          .timeout(const Duration(seconds: 15));
      if (searchRes.statusCode != 200) return null;

      final searchData = jsonDecode(searchRes.body);
      final List docs = searchData['docs'] ?? [];
      if (docs.isEmpty) return null;

      final firstAuthor = docs.first;
      final key = firstAuthor['key'];
      if (key == null) return null;

      String keyStr = key.toString();
      if (keyStr.startsWith('/authors/')) {
        keyStr = keyStr.replaceFirst('/authors/', '');
      }

      // 2. Fetch detailed author info
      final detailUrl = Uri.parse(
        'https://openlibrary.org/authors/$keyStr.json',
      );
      final detailRes = await http
          .get(detailUrl)
          .timeout(const Duration(seconds: 15));
      if (detailRes.statusCode != 200) return null;

      final detailData = jsonDecode(detailRes.body);

      // Handle bio as either String or Map
      String bio = 'No biography available.';
      if (detailData['bio'] != null) {
        if (detailData['bio'] is String) {
          bio = detailData['bio'];
        } else if (detailData['bio'] is Map &&
            detailData['bio']['value'] != null) {
          bio = detailData['bio']['value'];
        }
      }

      // Handle photo URL
      String? photoUrl;
      final List? photos = detailData['photos'];
      if (photos != null && photos.isNotEmpty) {
        final validPhotoId = photos.firstWhere(
          (p) => p != null && p is int && p > 0,
          orElse: () => null,
        );
        if (validPhotoId != null) {
          photoUrl = 'https://covers.openlibrary.org/b/id/$validPhotoId-L.jpg';
        }
      }

      // Wikipedia link
      String? wikipediaUrl = detailData['wikipedia'];

      return Author(
        name: detailData['name'] ?? authorName,
        bio: bio,
        birthDate: detailData['birth_date'],
        deathDate: detailData['death_date'],
        photoUrl: photoUrl,
        wikipediaUrl: wikipediaUrl,
      );
    } catch (e) {
      print('Error fetching author info: $e');
    }
    return null;
  }
}
