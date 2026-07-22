import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksService {
  // Hardcover API Token
  static const String _hardcoverToken = String.fromEnvironment('HARDCOVER_API_TOKEN', defaultValue: '');

  // Helper to normalize book titles for matching (stripping editions, subtitles & punctuation)
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '') // remove parenthesized tags e.g. "(Paperback)"
        .replaceAll(RegExp(r':.*'), '') // remove subtitles e.g. ": A Novel"
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // remove non-alphanumeric
  }

  // Strict completeness validator: book MUST have all essential fields populated
  bool isCompleteData(Book b) {
    if (b.title.trim().isEmpty || b.title.toLowerCase() == 'unknown title') return false;
    if (b.authors.isEmpty || (b.authors.length == 1 && b.authors.first.toLowerCase() == 'unknown author')) return false;
    if (b.description.trim().isEmpty || b.description.toLowerCase() == 'no description available.') return false;
    if (b.thumbnailUrl.trim().isEmpty) return false;
    if (b.publishedDate.trim().isEmpty || b.publishedDate.toLowerCase().contains('unknown')) return false;
    if (b.pageCount == null || b.pageCount! <= 0) return false;
    if (b.averageRating == null || b.averageRating! <= 0.0) return false;
    return true;
  }

  // Main search entry point using Hardcover GraphQL API with Open Library fallback
  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    if (_hardcoverToken.trim().isNotEmpty) {
      final hcResults = await _searchHardcover(query);
      if (hcResults.isNotEmpty) return hcResults;
    }

    return _searchOpenLibrary(query);
  }

  // Hardcover API search helper
  Future<List<Book>> _searchHardcover(String query) async {
    try {
      String cleanToken = _hardcoverToken.trim();
      if (cleanToken.toLowerCase().startsWith('bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final response = await http.post(
        Uri.parse('https://api.hardcover.app/v1/graphql'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
        body: jsonEncode({
          'query': '''
            query {
              search(query: "${query.replaceAll('"', '\\"')}") {
                results
              }
            }
          ''',
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> hits = body['data']?['search']?['results']?['hits'] ?? [];
        
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

          books.add(Book(
            id: id,
            title: title,
            authors: authors.isNotEmpty ? authors : ['Unknown Author'],
            description: description,
            thumbnailUrl: thumbnailUrl,
            publishedDate: doc['release_date'] ?? doc['release_year']?.toString() ?? '',
            pageCount: pages,
            averageRating: rating,
            categories: categories,
          ));
        }
        return books;
      }
    } catch (e) {
      print('Hardcover search error: $e');
    }
    return [];
  }

  // Open Library Search Engine with fast 4-second timeout (Fallback)
  Future<List<Book>> _searchOpenLibrary(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('https://openlibrary.org/search.json?q=$encodedQuery&limit=25');
      
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];
        
        List<Book> books = [];
        for (var doc in docs) {
          final key = doc['key'] as String? ?? '';
          if (key.isEmpty) continue;

          List<String> authors = [];
          if (doc['author_name'] != null) {
            authors = List<String>.from(doc['author_name']);
          }

          String thumbnailUrl = '';
          if (doc['cover_i'] != null) {
            thumbnailUrl = 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-M.jpg';
          } else if (doc['isbn'] != null && (doc['isbn'] as List).isNotEmpty) {
            thumbnailUrl = 'https://covers.openlibrary.org/b/isbn/${doc['isbn'][0]}-M.jpg';
          }

          int? pageCount = doc['number_of_pages_median'] ?? doc['number_of_pages'];

          String publishedDate = '';
          if (doc['publish_date'] != null && (doc['publish_date'] as List).isNotEmpty) {
            publishedDate = doc['publish_date'].first.toString();
          } else if (doc['first_publish_year'] != null) {
            publishedDate = doc['first_publish_year'].toString();
          }

          double? averageRating = doc['ratings_average'] != null 
              ? (doc['ratings_average'] as num).toDouble() 
              : null;

          List<String> categories = [];
          if (doc['subject'] != null) {
            categories = List<String>.from(doc['subject']);
          }

          books.add(Book(
            id: key,
            title: doc['title'] ?? 'Unknown Title',
            authors: authors.isNotEmpty ? authors : ['Unknown Author'],
            description: '',
            thumbnailUrl: thumbnailUrl,
            publishedDate: publishedDate,
            pageCount: pageCount,
            averageRating: averageRating,
            categories: categories,
          ));
        }
        return books;
      }
    } catch (e) {
      print('Error searching Open Library: $e');
    }
    return [];
  }

  // Get specific book details from Hardcover with Open Library fallback
  Future<Book?> getBookDetails(String id) async {
    if (id.trim().isEmpty) return null;

    if (int.tryParse(id) != null && _hardcoverToken.isNotEmpty) {
      final hardcoverBook = await _getHardcoverBookDetails(id);
      if (hardcoverBook != null) return hardcoverBook;
    }

    return _getOpenLibraryBookDetails(id);
  }

  Future<Book?> _getHardcoverBookDetails(String id) async {
    try {
      String cleanToken = _hardcoverToken.trim();
      if (cleanToken.toLowerCase().startsWith('bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final response = await http.post(
        Uri.parse('https://api.hardcover.app/v1/graphql'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
        body: jsonEncode({
          'query': '''
            query {
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
        }),
      ).timeout(const Duration(seconds: 4));

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
          publishedDate: data['release_date'] ?? data['release_year']?.toString() ?? '',
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

  Future<Book?> _getOpenLibraryBookDetails(String id) async {
    try {
      final cleanId = id.startsWith('/') ? id : '/works/$id';
      final url = Uri.parse('https://openlibrary.org$cleanId.json');

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      String title = data['title'] ?? 'Unknown Title';
      String description = '';
      if (data['description'] != null) {
        if (data['description'] is String) {
          description = data['description'];
        } else if (data['description'] is Map && data['description']['value'] != null) {
          description = data['description']['value'];
        }
      }

      String thumbnailUrl = '';
      if (data['covers'] != null && (data['covers'] as List).isNotEmpty) {
        thumbnailUrl = 'https://covers.openlibrary.org/b/id/${data['covers'][0]}-L.jpg';
      }

      List<String> authors = [];
      if (data['authors'] != null && (data['authors'] as List).isNotEmpty) {
        for (var authorRef in data['authors']) {
          final authorKey = authorRef['author']?['key'];
          if (authorKey != null) {
            final authorUrl = Uri.parse('https://openlibrary.org$authorKey.json');
            final authorRes = await http.get(authorUrl).timeout(const Duration(seconds: 3));
            if (authorRes.statusCode == 200) {
              final authorData = json.decode(authorRes.body);
              if (authorData['name'] != null) {
                authors.add(authorData['name']);
              }
            }
          }
        }
      }

      return Book(
        id: id,
        title: title,
        authors: authors.isNotEmpty ? authors : ['Unknown Author'],
        description: description,
        thumbnailUrl: thumbnailUrl,
        publishedDate: '',
        categories: const [],
      );
    } catch (e) {
      print('Error getting Open Library book details: $e');
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
        final popularTerms = ['fiction', 'fantasy', 'thriller', 'sci-fi', 'bestseller'];
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
        if (existingIds.contains(b.id) || existingNormalizedTitles.contains(normalizedCandidate)) {
          continue;
        }

        if (!uniqueMap.containsKey(normalizedCandidate)) {
          uniqueMap[normalizedCandidate] = b;
        }
      }

      // STRICT FILTER: Must have COMPLETE DATA (all fields present) and rating < 5.0
      List<Book> filtered = uniqueMap.values.where((b) {
        if (!isCompleteData(b)) return false; // Ignore incomplete books!
        return b.averageRating! < 5.0; // Ignore 5-star books!
      }).toList();

      // Sort by highest rating first + genre match bonus!
      filtered.sort((a, b) {
        final ratingA = a.averageRating ?? 0.0;
        final ratingB = b.averageRating ?? 0.0;

        final bool genreMatchA = a.categories.any((c) => userGenres.contains(c)) ||
            a.authors.any((auth) => userAuthors.contains(auth));
        final bool genreMatchB = b.categories.any((c) => userGenres.contains(c)) ||
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
