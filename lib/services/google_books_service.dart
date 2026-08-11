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

  // Validate that a recommended book has rich info for display:
  // title, authors, description (non-empty, non-default), and page count.
  bool _hasCompleteDisplayInfo(Book b) {
    if (!isCompleteData(b)) return false;
    // Must have a real description (not the default "No description available.")
    final desc = b.description.trim().toLowerCase();
    if (desc.isEmpty || desc == 'no description available.') return false;
    // Must have page count
    if (b.pageCount == null || b.pageCount! <= 0) return false;
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

  // Fetch randomized book recommendations with author diversity,
  // only including books with complete info and below-perfect ratings.
  Future<List<Book>> fetchBookRecommendations(List<Book> userBooks) async {
    if (userBooks.isEmpty) return [];

    try {
      final existingIds = userBooks.map((b) => b.id).toSet();
      final existingNormalizedTitles = userBooks
          .map((b) => _normalizeTitle(b.title))
          .where((t) => t.isNotEmpty)
          .toSet();
      final random = Random();

      // Collect the set of "seed" author names already in the user's library
      final existingAuthors = userBooks
          .expand((b) => b.authors)
          .where((a) => a.toLowerCase() != 'unknown author')
          .toSet();

      final userGenres = userBooks
          .expand((b) => b.categories)
          .where((c) => c.trim().isNotEmpty)
          .toSet();

      // Build a diverse set of search queries to gather candidates.
      // Mix of authors (from user's library), genres, and fallback terms.
      List<String> queryList = [];

      final authorList = existingAuthors.toList()..shuffle(random);
      queryList.addAll(authorList.take(3));

      final genreList = userGenres.toList()..shuffle(random);
      queryList.addAll(genreList.take(3));

      if (queryList.length < 4) {
        final popularTerms = [
          'fiction',
          'fantasy',
          'thriller',
          'sci-fi',
          'bestseller',
          'mystery',
          'romance',
        ];
        popularTerms.shuffle(random);
        queryList.addAll(popularTerms.take(3));
      }

      // Execute search queries IN PARALLEL for speed
      final searchFutures = queryList.map((q) => searchBooks(q)).toList();
      final searchResults = await Future.wait(searchFutures);

      List<Book> candidatePool = [];
      for (var list in searchResults) {
        candidatePool.addAll(list);
      }

      // Deduplicate candidates by normalized title
      final Map<String, Book> uniqueMap = {};
      for (var b in candidatePool) {
        final normalizedCandidate = _normalizeTitle(b.title);
        if (existingIds.contains(b.id) ||
            existingNormalizedTitles.contains(normalizedCandidate)) {
          continue;
        }
        if (!uniqueMap.containsKey(normalizedCandidate)) {
          uniqueMap[normalizedCandidate] = b;
        }
      }

      // Enrich details for candidates that might be missing data
      final detailFutures = uniqueMap.values.take(20).map((b) async {
        if (!isCompleteData(b) || !_hasCompleteDisplayInfo(b)) {
          final detailed = await getBookDetails(b.id);
          if (detailed != null && _hasCompleteDisplayInfo(detailed)) {
            return detailed;
          }
        }
        return b;
      }).toList();
      final enrichedCandidates = await Future.wait(detailFutures);

      // Filter: only books with complete display info AND below 5-star rating
      List<Book> filtered = enrichedCandidates.where((b) {
        // Must have complete info
        if (!_hasCompleteDisplayInfo(b)) return false;
        // Must NOT have a perfect 5-star rating
        if (b.averageRating != null && b.averageRating! >= 5.0) return false;
        return true;
      }).toList();

      // --- Author Diversity + Randomization ---
      // Group books by their first author so we can spread across authors.
      final Map<String, List<Book>> byFirstAuthor = {};
      for (var b in filtered) {
        final firstAuthor = b.authors.isNotEmpty
            ? b.authors.first.toLowerCase()
            : 'unknown';
        byFirstAuthor.putIfAbsent(firstAuthor, () => []).add(b);
      }

      final authorKeys = byFirstAuthor.keys.toList()..shuffle(random);
      final List<Book> diversified = [];
      final usedIds = <String>{};
      var safetyCounter = 0;

      while (diversified.length < 10 && safetyCounter < 100) {
        for (var key in authorKeys) {
          if (diversified.length >= 10) break;
          if (safetyCounter >= 100) break;
          final booksForAuthor = byFirstAuthor[key]!;
          if (booksForAuthor.isEmpty) continue;

          // Pick books from this author that haven't been used yet
          final unused =
              booksForAuthor.where((b) => !usedIds.contains(b.id)).toList();
          if (unused.isEmpty) continue;

          unused.shuffle(random);
          final pick = unused.first;
          if (pick.averageRating != null && pick.averageRating! >= 5.0) {
            continue;
          }
          diversified.add(pick);
          usedIds.add(pick.id);
          safetyCounter++;
        }
      }

      // Shuffle the final result for randomness
      diversified.shuffle(random);
      return diversified.take(10).toList();
    } catch (e) {
      print('Error fetching fast recommendations: $e');
      return [];
    }
  }
}
