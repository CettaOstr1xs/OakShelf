import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'token_helper.dart';

class GoogleBooksService {
  // Hardcover API Token Loader
  Future<String> _getApiToken() async {
    return await getHardcoverToken();
  }

  // Helper to normalize book titles for matching (stripping editions, subtitles & punctuation)
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(
          RegExp(r'\(.*?\)|\[.*?\]'),
          '',
        ) // remove parenthesized tags e.g. "(Paperback)"
        .replaceAll(RegExp(r':.*'), '') // remove subtitles e.g. ": A Novel"
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // remove non-alphanumeric
  }

  // Completeness validator: book MUST have title and authors
  bool isCompleteData(Book b) {
    if (b.title.trim().isEmpty || b.title.toLowerCase() == 'unknown title')
      return false;
    if (b.authors.isEmpty ||
        (b.authors.length == 1 &&
            b.authors.first.toLowerCase() == 'unknown author'))
      return false;
    return true;
  }

  // Main search entry point using Hardcover GraphQL API
  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final token = await _getApiToken();
    if (token.trim().isNotEmpty) {
      return _searchHardcover(query, token);
    }

    return [];
  }

  // Hardcover API search helper
  Future<List<Book>> _searchHardcover(String query, String token) async {
    try {
      String cleanToken = token.trim();
      if (cleanToken.toLowerCase().startsWith('bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final response = await http
          .post(
            Uri.parse('https://api.hardcover.app/v1/graphql'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $cleanToken',
            },
            body: jsonEncode({
              'query': r'''
            query SearchBooks($q: String!) {
              search(query: $q) {
                results
              }
            }
          ''',
              'variables': {'q': query},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> hits =
            body['data']?['search']?['results']?['hits'] ?? [];

        List<Book> books = [];
        for (var result in hits) {
          final doc = result['document'];
          if (doc == null) continue;

          final id = doc['id'].toString();
          final title = doc['title'] ?? 'Unknown Title';
          final description = doc['description'] ?? '';
          final pages = doc['pages'] as int?;
          final rating = (doc['rating'] as num?)?.toDouble();

          String thumbnailUrl = '';
          if (doc['image'] != null && doc['image']['url'] != null) {
            thumbnailUrl = doc['image']['url'];
          }

          List<String> authors = [];
          if (doc['author_names'] != null) {
            authors = List<String>.from(doc['author_names']);
          }

          List<String> categories = [];
          if (doc['genres'] != null) {
            categories = List<String>.from(doc['genres']);
          }

          books.add(
            Book(
              id: id,
              title: title,
              authors: authors.isNotEmpty ? authors : ['Unknown Author'],
              description: description,
              thumbnailUrl: thumbnailUrl,
              publishedDate:
                  doc['release_date'] ?? doc['release_year']?.toString() ?? '',
              pageCount: pages,
              averageRating: rating,
              categories: categories,
            ),
          );
        }
        return books;
      }
    } catch (e) {
      print('Hardcover search error: $e');
    }
    return [];
  }

  // Get specific book details from Hardcover API
  Future<Book?> getBookDetails(String id) async {
    if (id.trim().isEmpty) return null;

    final token = await _getApiToken();
    if (int.tryParse(id) != null && token.isNotEmpty) {
      return _getHardcoverBookDetails(id, token);
    }

    return null;
  }

  Future<Book?> _getHardcoverBookDetails(String id, String token) async {
    try {
      String cleanToken = token.trim();
      if (cleanToken.toLowerCase().startsWith('bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final intId = int.tryParse(id);
      if (intId == null) return null;

      final response = await http
          .post(
            Uri.parse('https://api.hardcover.app/v1/graphql'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $cleanToken',
            },
            body: jsonEncode({
              'query': r'''
            query GetBookDetails($id: Int!) {
              books_by_pk(id: $id) {
                id
                title
                description
                pages
                rating
                release_date
                release_year
                image { url }
                contributions { author { name } }
              }
            }
          ''',
              'variables': {'id': intId},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']?['books_by_pk'];
        if (data == null) return null;

        List<String> authors = [];
        if (data['contributions'] != null) {
          for (var c in data['contributions']) {
            if (c['author'] != null && c['author']['name'] != null) {
              authors.add(c['author']['name']);
            }
          }
        }

        return Book(
          id: data['id'].toString(),
          title: data['title'] ?? '',
          authors: authors.isNotEmpty ? authors : ['Unknown Author'],
          description: data['description'] ?? '',
          thumbnailUrl: data['image']?['url'] ?? '',
          publishedDate:
              data['release_date'] ?? data['release_year']?.toString() ?? '',
          pageCount: data['pages'] as int?,
          averageRating: (data['rating'] as num?)?.toDouble(),
          categories: const [],
        );
      }
    } catch (e) {
      print('Error fetching Hardcover details: $e');
    }
    return null;
  }

  // Fetch ultra-fast recommendations in parallel, strictly filtering out incomplete data books & 5-star/duplicate titles
  Future<List<Book>> fetchBookRecommendations(List<Book> userBooks) async {
    if (userBooks.isEmpty) return [];

    try {
      final existingIds = userBooks.map((b) => b.id).toSet();
      final existingNormalizedTitles = userBooks
          .map((b) => _normalizeTitle(b.title))
          .where((t) => t.isNotEmpty)
          .toSet();
      final random = Random();

      // Extract authors and genres
      Set<String> userGenres = {};
      Set<String> userAuthors = {};

      for (var b in userBooks) {
        for (var cat in b.categories) {
          if (cat.trim().isNotEmpty) userGenres.add(cat.trim());
        }
        for (var a in b.authors) {
          if (a.isNotEmpty && a != 'Unknown Author') userAuthors.add(a.trim());
        }
      }

      // Prepare search queries to run in parallel
      List<String> queryList = [];

      List<String> authorList = userAuthors.toList()..shuffle(random);
      queryList.addAll(authorList.take(2));

      List<String> genreList = userGenres.toList()..shuffle(random);
      queryList.addAll(genreList.take(2));

      if (queryList.length < 3) {
        final popularTerms = [
          'fiction',
          'fantasy',
          'thriller',
          'sci-fi',
          'bestseller',
        ];
        popularTerms.shuffle(random);
        queryList.addAll(popularTerms.take(3));
      }

      // ULTRA FAST LOAD: Execute search queries IN PARALLEL!
      final searchFutures = queryList.map((q) => searchBooks(q)).toList();
      final searchResults = await Future.wait(searchFutures);

      List<Book> candidatePool = [];
      for (var list in searchResults) {
        candidatePool.addAll(list);
      }

      // Enrich missing details for candidates if needed
      final detailFutures = candidatePool.take(15).map((b) async {
        if (!isCompleteData(b)) {
          final detailed = await getBookDetails(b.id);
          return detailed ?? b;
        }
        return b;
      }).toList();

      final enrichedCandidates = await Future.wait(detailFutures);

      // Deduplicate candidate books and filter out existing bookshelf titles/editions
      final Map<String, Book> uniqueMap = {};
      for (var b in enrichedCandidates) {
        final normalizedCandidate = _normalizeTitle(b.title);

        // EXCLUDE if ID matches OR if title/edition matches a book already in bookshelf!
        if (existingIds.contains(b.id) ||
            existingNormalizedTitles.contains(normalizedCandidate)) {
          continue;
        }

        if (!uniqueMap.containsKey(normalizedCandidate)) {
          uniqueMap[normalizedCandidate] = b;
        }
      }

      // Relaxed Filter: Must have basic title and author details
      List<Book> filtered = uniqueMap.values.where((b) {
        return isCompleteData(b);
      }).toList();

      // Sort by highest rating first + genre match bonus!
      filtered.sort((a, b) {
        final ratingA = a.averageRating ?? 0.0;
        final ratingB = b.averageRating ?? 0.0;

        final bool genreMatchA =
            a.categories.any((c) => userGenres.contains(c)) ||
            a.authors.any((auth) => userAuthors.contains(auth));
        final bool genreMatchB =
            b.categories.any((c) => userGenres.contains(c)) ||
            b.authors.any((auth) => userAuthors.contains(auth));

        final scoreA = ratingA + (genreMatchA ? 0.3 : 0.0);
        final scoreB = ratingB + (genreMatchB ? 0.3 : 0.0);

        return scoreB.compareTo(scoreA);
      });

      return filtered.take(10).toList();
    } catch (e) {
      print('Error fetching fast recommendations: $e');
      return [];
    }
  }
}
