import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../models/quote.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseService() {
    // Enable unlimited local cache persistence for seamless offline usage
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Retrieve current user UID
  String? get currentUid => _auth.currentUser?.uid;

  // Helper to sanitize Firestore document keys by replacing slashes
  String _sanitizeId(String rawId) {
    return rawId.replaceAll('/', '_');
  }

  // Perform silent anonymous sign-in with offline safety
  Future<String?> signInAnonymously() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        final credential = await _auth.signInAnonymously().timeout(
          const Duration(seconds: 4),
        );
        user = credential.user;
      }
      return user?.uid;
    } catch (e) {
      print('Offline or anonymous auth notice: $e');
      return _auth.currentUser?.uid;
    }
  }

  // Get collection references for the active user
  CollectionReference get _userBooksRef {
    final uid = currentUid;
    if (uid == null) throw Exception('User authentication required');
    return _db.collection('users').doc(uid).collection('books');
  }

  CollectionReference get _userQuotesRef {
    final uid = currentUid;
    if (uid == null) throw Exception('User authentication required');
    return _db.collection('users').doc(uid).collection('quotes');
  }

  // Real-time stream of all saved books in user library (works offline & online)
  Stream<List<Book>> getBookShelfStream() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('books')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final books = <Book>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              if (data is Map<String, dynamic>) {
                books.add(Book.fromStorageJson(data));
              }
            } catch (e) {
              // Keep one malformed cached document from blanking the library.
              print('Skipping malformed book ${doc.id}: $e');
            }
          }
          return books;
        });
  }

  // Fetch a single book from user storage (queries server with cache fallback when offline)
  Future<Book?> getBook(String bookId) async {
    try {
      final sanitizedId = _sanitizeId(bookId);

      try {
        final doc = await _userBooksRef.doc(sanitizedId).get();
        if (doc.exists && doc.data() != null) {
          return Book.fromStorageJson(doc.data() as Map<String, dynamic>);
        }
      } catch (_) {
        final docCache = await _userBooksRef
            .doc(sanitizedId)
            .get(const GetOptions(source: Source.cache));
        if (docCache.exists && docCache.data() != null) {
          return Book.fromStorageJson(docCache.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Error fetching book offline/online: $e');
    }
    return null;
  }

  // Save or update book in library (writes to local cache immediately when offline)
  Future<void> saveBook(Book book) async {
    try {
      final docId = _sanitizeId(book.id);

      if (book.shelf != ShelfStatus.none && book.dateAdded == null) {
        book.dateAdded = DateTime.now();
      }

      if (book.shelf == ShelfStatus.none &&
          book.customShelves.isEmpty &&
          book.userRating == 0.0 &&
          book.userReview.trim().isEmpty &&
          book.currentPage == 0) {
        await _userBooksRef.doc(docId).delete();
      } else {
        await _userBooksRef
            .doc(docId)
            .set(book.toStorageJson(), SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving book offline/online: $e');
    }
  }

  // Real-time stream of user saved quotes (works offline & online)
  Stream<List<Quote>> getQuotesStream() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('quotes')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final List<Quote> list = snapshot.docs
              .map(
                (doc) =>
                    Quote.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();
          list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          return list;
        });
  }

  // Save quote to library
  Future<void> saveQuote(Quote quote) async {
    try {
      final docRef = _userQuotesRef.doc();
      final quoteData = quote.toMap();
      await docRef.set(quoteData);
    } catch (e) {
      print('Error saving quote offline/online: $e');
    }
  }

  // Delete quote from library
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _userQuotesRef.doc(quoteId).delete();
    } catch (e) {
      print('Error deleting quote: $e');
    }
  }

  // Real-time stream for Reading Challenge Goal (default 12 books)
  Stream<int> getReadingGoalStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value(12);

    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('challenge')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return (snapshot.data()!['goal'] as num? ?? 12).toInt();
          }
          return 12;
        });
  }

  // Save new reading goal target
  Future<void> saveReadingGoal(int goal) async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('challenge')
          .set({'goal': goal}, SetOptions(merge: true));
    } catch (e) {
      print('Error saving reading goal: $e');
    }
  }

  // Stream of user custom shelf names
  Stream<List<String>> getCustomShelvesStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('custom_shelves')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final list = snapshot.data()!['shelves'];
            if (list is List) {
              return List<String>.from(list);
            }
          }
          return [];
        });
  }

  // Create a new custom bookshelf by name (Instant non-blocking local + cloud write)
  Future<void> createCustomShelf(String name) async {
    final uid = currentUid;
    if (uid == null) return;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    // Fire and forget so UI dialog closes with zero lag (< 1ms)
    _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('custom_shelves')
        .set({
          'shelves': FieldValue.arrayUnion([trimmedName]),
        }, SetOptions(merge: true))
        .catchError((e) {
          print('Error creating custom shelf: $e');
        });
  }

  // Delete a custom bookshelf by name (Instant non-blocking local + cloud cleanup)
  Future<void> deleteCustomShelf(String name) async {
    final uid = currentUid;
    if (uid == null) return;

    // Fire and forget so UI closes immediately without freezing or crashing
    _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('custom_shelves')
        .set({
          'shelves': FieldValue.arrayRemove([name]),
        }, SetOptions(merge: true))
        .catchError((e) {
          print('Error deleting custom shelf: $e');
        });

    // Clean up custom shelf assignment from books
    try {
      final snapshot = await _userBooksRef.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['customShelves'] != null) {
          final List customList = List.from(data['customShelves']);
          if (customList.contains(name)) {
            customList.remove(name);
            doc.reference.update({'customShelves': customList});
          }
        }
      }
    } catch (_) {}
  }
}
