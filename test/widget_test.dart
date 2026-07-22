import 'package:flutter_test/flutter_test.dart';
import 'package:bookery/main.dart';
import 'package:bookery/models/book.dart';
import 'package:bookery/models/quote.dart';
import 'package:bookery/services/google_books_service.dart';
import 'package:bookery/services/firebase_service.dart';

// Stub implementation of FirebaseService to bypass real native SDK checks during tests
class MockFirebaseService implements FirebaseService {
  @override
  String? get currentUid => 'mock-test-uid';

  @override
  Future<String?> signInAnonymously() async => 'mock-test-uid';

  @override
  Stream<List<Book>> getBookShelfStream() => Stream.value([]);

  @override
  Future<Book?> getBook(String bookId) async => null;

  @override
  Future<void> saveBook(Book book) async {}

  @override
  Stream<List<Quote>> getQuotesStream() => Stream.value([]);

  @override
  Future<void> saveQuote(Quote quote) async {}

  @override
  Future<void> deleteQuote(String quoteId) async {}

  @override
  Stream<int> getReadingGoalStream() => Stream.value(12);

  @override
  Future<void> saveReadingGoal(int goal) async {}

  @override
  Stream<List<String>> getCustomShelvesStream() => Stream.value([]);

  @override
  Future<void> createCustomShelf(String name) async {}

  @override
  Future<void> deleteCustomShelf(String name) async {}
}

void main() {
  testWidgets('App renders main navigation shell smoke test', (WidgetTester tester) async {
    final mockFirebaseService = MockFirebaseService();
    final apiService = GoogleBooksService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      firebaseService: mockFirebaseService,
      apiService: apiService,
    ));
    await tester.pumpAndSettle();

    // Verify that the Bookery shell renders correctly
    expect(find.text('Bookery Feed'), findsOneWidget);
  });
}
