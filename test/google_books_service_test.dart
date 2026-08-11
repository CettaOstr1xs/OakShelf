import 'package:flutter_test/flutter_test.dart';
import 'package:bookery/services/google_books_service.dart';
import 'package:bookery/models/book.dart';

void main() {
  test('GoogleBooksService fetches book recommendations and filters duplicates correctly', () async {
    final service = GoogleBooksService();
    
    // Seed with a book to search for matching genres/authors
    final userBooks = [
      Book(
        id: '2459845',
        title: 'The Hobbit',
        authors: ['J.R.R. Tolkien'],
        description: 'Bilbo Baggins journey',
        thumbnailUrl: 'https://assets.hardcover.app/edition/17456445/d34448a9-bf3f-441d-93f2-1cd32dd3867c.jpg',
        publishedDate: '1937-09-21',
        categories: ['Fantasy', 'Classics'],
        pageCount: 320,
        averageRating: 4.3,
        shelf: ShelfStatus.read,
      ),
    ];

    final recs = await service.fetchBookRecommendations(userBooks);
    
    expect(recs, isNotNull);
    expect(recs, isNotEmpty);
    
    for (var r in recs) {
      // Ensure seed book is excluded
      expect(r.id, isNot(equals('2459845')));
      expect(r.title.toLowerCase(), isNot(equals('the hobbit')));
      
      // Verify basic fields are present
      expect(r.title, isNotEmpty);
      expect(r.authors, isNotEmpty);
    }
  });
}
