class Quote {
  final String id;
  final String quoteText;
  final String author;
  final String bookTitle;
  final DateTime dateAdded;

  Quote({
    required this.id,
    required this.quoteText,
    required this.author,
    required this.bookTitle,
    required this.dateAdded,
  });

  // Convert to Map for database persistence
  Map<String, dynamic> toMap() {
    return {
      'quoteText': quoteText,
      'author': author,
      'bookTitle': bookTitle,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Create Quote instance from database Map
  factory Quote.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['dateAdded'] != null) {
      if (map['dateAdded'] is String) {
        parsedDate = DateTime.tryParse(map['dateAdded']) ?? DateTime.now();
      } else {
        try {
          parsedDate = (map['dateAdded'] as dynamic).toDate();
        } catch (_) {
          // If already a DateTime
          if (map['dateAdded'] is DateTime) {
            parsedDate = map['dateAdded'];
          }
        }
      }
    }

    return Quote(
      id: id,
      quoteText: map['quoteText'] ?? '',
      author: map['author'] ?? 'Unknown',
      bookTitle: map['bookTitle'] ?? '',
      dateAdded: parsedDate,
    );
  }
}
