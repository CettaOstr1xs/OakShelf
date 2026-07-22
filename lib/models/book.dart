enum ShelfStatus {
  none,
  wantToRead,
  reading,
  read,
}

extension ShelfStatusExtension on ShelfStatus {
  String get displayName {
    switch (this) {
      case ShelfStatus.wantToRead:
        return 'Want to Read';
      case ShelfStatus.reading:
        return 'Reading';
      case ShelfStatus.read:
        return 'Read';
      case ShelfStatus.none:
        return 'None';
    }
  }
}

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnailUrl;
  final String publishedDate;
  final int? pageCount;
  double? averageRating;
  final List<String> categories;

  // Custom User Review & Shelf State
  ShelfStatus shelf;
  List<String> customShelves; // Custom user-created shelf names
  double userRating; // 0.0 means unrated
  String userReview;
  int currentPage;
  DateTime? dateAdded;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedDate,
    this.pageCount,
    this.averageRating,
    required this.categories,
    this.shelf = ShelfStatus.none,
    List<String>? customShelves,
    this.userRating = 0.0,
    this.userReview = '',
    this.currentPage = 0,
    this.dateAdded,
  }) : customShelves = customShelves ?? [];

  // Factory to create a Book from Google Books API JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    
    // Parse authors
    List<String> authorsList = [];
    if (volumeInfo['authors'] != null) {
      authorsList = List<String>.from(volumeInfo['authors']);
    }

    // Parse categories
    List<String> categoriesList = [];
    if (volumeInfo['categories'] != null) {
      categoriesList = List<String>.from(volumeInfo['categories']);
    }

    // Find thumbnail image
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    String thumbnail = '';
    if (imageLinks != null) {
      thumbnail = (imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'] ?? '').toString();
      // Enforce HTTPS
      if (thumbnail.startsWith('http://')) {
        thumbnail = thumbnail.replaceFirst('http://', 'https://');
      }
    }

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Unknown Title',
      authors: authorsList.isNotEmpty ? authorsList : ['Unknown Author'],
      description: volumeInfo['description'] ?? 'No description available.',
      thumbnailUrl: thumbnail,
      publishedDate: volumeInfo['publishedDate'] ?? 'Unknown date',
      pageCount: volumeInfo['pageCount'] as int?,
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble(),
      categories: categoriesList,
    );
  }

  // To serialize user data to local storage JSON
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'averageRating': averageRating,
      'categories': categories,
      'shelf': shelf.name,
      'customShelves': customShelves,
      'userRating': userRating,
      'userReview': userReview,
      'currentPage': currentPage,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  // From local storage JSON
  factory Book.fromStorageJson(Map<String, dynamic> json) {
    final shelfName = json['shelf'] as String? ?? 'none';
    final shelfStatus = ShelfStatus.values.firstWhere(
      (e) => e.name == shelfName,
      orElse: () => ShelfStatus.none,
    );

    DateTime? parsedDate;
    if (json['dateAdded'] != null) {
      if (json['dateAdded'] is String) {
        parsedDate = DateTime.tryParse(json['dateAdded']);
      } else {
        try {
          parsedDate = (json['dateAdded'] as dynamic).toDate();
        } catch (_) {
          if (json['dateAdded'] is DateTime) {
            parsedDate = json['dateAdded'];
          }
        }
      }
    }

    List<String> parsedCustom = [];
    if (json['customShelves'] != null) {
      parsedCustom = List<String>.from(json['customShelves']);
    }

    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      authors: json['authors'] != null ? List<String>.from(json['authors']) : ['Unknown Author'],
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publishedDate: json['publishedDate'] ?? '',
      pageCount: json['pageCount'] as int?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      categories: json['categories'] != null ? List<String>.from(json['categories']) : [],
      shelf: shelfStatus,
      customShelves: parsedCustom,
      userRating: (json['userRating'] as num?)?.toDouble() ?? 0.0,
      userReview: json['userReview'] ?? '',
      currentPage: json['currentPage'] as int? ?? 0,
      dateAdded: parsedDate,
    );
  }
}
