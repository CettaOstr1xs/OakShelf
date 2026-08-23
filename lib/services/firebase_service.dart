import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/quote.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Local key that pins this device's library location in Firestore.
  ///
  /// Anonymous auth sessions can be reset (app data cleared, reinstall,
  /// expired session, offline first launch). When that happens a NEW uid is
  /// issued and any data keyed under the old uid appears "gone". Persisting
  /// the first known uid here keeps every launch reading/writing the same
  /// Firestore path regardless of auth identity changes.
  static const String _ownerKeyPref = 'oakshelf_owner_key';
  static const String _guestOwnerId = 'local-guest';
  String? _cachedOwnerKey;

  FirebaseService() {
    // Enable unlimited local cache persistence for seamless offline usage
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Retrieve current user UID
  String? get currentUid => _auth.currentUser?.uid;

  // Stable storage identity used for all Firestore paths.
  String get storageOwnerId => _cachedOwnerKey ?? currentUid ?? _guestOwnerId;

  // Backwards-compatible entry point used by main.dart and tests.
  Future<String?> signInAnonymously() => ensureSignedIn();

  // Signs in anonymously with retries so a slow network or an offline first
  // launch cannot leave the app permanently signed out (and looking empty).
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async {
    User? user = _auth.currentUser;
    for (var attempt = 0; attempt < maxAttempts && user == null; attempt++) {
      try {
        final credential = await _auth
            .signInAnonymously()
            .timeout(const Duration(seconds: 10));
        user = credential.user;
      } catch (e) {
        debugPrint('Anonymous sign-in attempt ${attempt + 1} failed: $e');
      }
      user ??= _auth.currentUser;
      if (user == null && attempt + 1 < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }

    if (user != null) {
      await _pinOwnerKey(user.uid);
    } else {
      debugPrint('FirebaseService: continuing unauthenticated as $_guestOwnerId');
    }
    return user?.uid;
  }

  Future<void> _pinOwnerKey(String uid) async {
    if (_cachedOwnerKey != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_ownerKeyPref);
      final validStored = stored != null && stored.isNotEmpty && stored != _guestOwnerId;
      if (!validStored) {
        await prefs.setString(_ownerKeyPref, uid);
        _cachedOwnerKey = uid;
      } else {
        _cachedOwnerKey = stored;
      }
    } catch (e) {
      debugPrint('Could not persist owner key, using current uid: $e');
      _cachedOwnerKey ??= uid;
    }
  }

  // Helper to sanitize Firestore document keys by replacing slashes
  String _sanitizeId(String rawId) {
    return rawId.replaceAll('/', '_');
  }

  // Get collection references for the stable storage owner
  CollectionReference get _userBooksRef =>
      _db.collection('users').doc(storageOwnerId).collection('books');

  CollectionReference get _userQuotesRef =>
      _db.collection('users').doc(storageOwnerId).collection('quotes');

  CollectionReference get _userSettingsRef =>
      _db.collection('users').doc(storageOwnerId).collection('settings');

  // Real-time stream of all saved books in user library (works offline & online)
  Stream<List<Book>> getBookShelfStream() async* {
    await ensureSignedIn();
    yield* _userBooksRef
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
              debugPrint('Skipping malformed book ${doc.id}: $e');
            }
          }
          debugPrint(
            '[OakShelf] library owner=$storageOwnerId docs=${books.length} '
            'fromCache=${snapshot.metadata.isFromCache} '
            'pendingWrites=${snapshot.metadata.hasPendingWrites}',
          );
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
      debugPrint('Error fetching book offline/online: $e');
    }
    return null;
  }

  // Save or update book in library (writes to local cache immediately when offline)
  Future<void> saveBook(Book book) async {
    try {
      await ensureSignedIn(maxAttempts: 1);
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
      debugPrint('Error saving book offline/online: $e');
    }
  }

  // Real-time stream of user saved quotes (works offline & online)
  Stream<List<Quote>> getQuotesStream() async* {
    await ensureSignedIn();
    yield* _userQuotesRef.snapshots(includeMetadataChanges: true).map((
      snapshot,
    ) {
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
      await ensureSignedIn(maxAttempts: 1);
      final docRef = _userQuotesRef.doc();
      await docRef.set(quote.toMap());
    } catch (e) {
      debugPrint('Error saving quote offline/online: $e');
    }
  }

  // Delete quote from library
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _userQuotesRef.doc(quoteId).delete();
    } catch (e) {
      debugPrint('Error deleting quote: $e');
    }
  }

  // Real-time stream for Reading Challenge Goal (default 12 books)
  Stream<int> getReadingGoalStream() async* {
    await ensureSignedIn();
    yield* _userSettingsRef.doc('challenge').snapshots(
      includeMetadataChanges: true,
    ).map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ((snapshot.data() as Map<String, dynamic>)['goal'] as num? ?? 12)
            .toInt();
      }
      return 12;
    });
  }

  // Save new reading goal target
  Future<void> saveReadingGoal(int goal) async {
    try {
      await ensureSignedIn(maxAttempts: 1);
      await _userSettingsRef
          .doc('challenge')
          .set({'goal': goal}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving reading goal: $e');
    }
  }

  // Stream of user custom shelf names
  Stream<List<String>> getCustomShelvesStream() async* {
    await ensureSignedIn();
    yield* _userSettingsRef.doc('custom_shelves').snapshots(
      includeMetadataChanges: true,
    ).map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final list =
            (snapshot.data() as Map<String, dynamic>)['shelves'];
        if (list is List) {
          return List<String>.from(list);
        }
      }
      return <String>[];
    });
  }

  // Create a new custom bookshelf by name (Instant non-blocking local + cloud write)
  Future<void> createCustomShelf(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    await ensureSignedIn(maxAttempts: 1);

    // Fire and forget so UI dialog closes with zero lag (< 1ms)
    _userSettingsRef
        .doc('custom_shelves')
        .set({
          'shelves': FieldValue.arrayUnion([trimmedName]),
        }, SetOptions(merge: true))
        .catchError((e) {
          debugPrint('Error creating custom shelf: $e');
        });
  }

  // Delete a custom bookshelf by name (Instant non-blocking local + cloud cleanup)
  Future<void> deleteCustomShelf(String name) async {
    await ensureSignedIn(maxAttempts: 1);
    // Fire and forget so UI closes immediately without freezing or crashing
    _userSettingsRef
        .doc('custom_shelves')
        .set({
          'shelves': FieldValue.arrayRemove([name]),
        }, SetOptions(merge: true))
        .catchError((e) {
          debugPrint('Error deleting custom shelf: $e');
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

  // Copies books, quotes, goal and custom shelves from a previous account ID
  // into this device's storage root. Used to recover a library that ended up
  // stranded under an old anonymous uid. Non-destructive merge.
  //
  // Every phase is attempted independently so one failing collection cannot
  // hide what actually succeeded or why something failed.
  Future<RestoreResult> restoreFromOwner(String legacyOwnerId) async {
    final legacyId = legacyOwnerId.trim();
    if (legacyId.isEmpty) {
      throw Exception('Enter the previous account ID to restore from.');
    }
    if (legacyId == storageOwnerId) {
      throw Exception(
        'That ID is already this device\'s active Storage ID. '
        'Paste the OLDER account UID instead.',
      );
    }

    await ensureSignedIn();

    var booksCopied = 0;
    var quotesCopied = 0;
    final errors = <String>[];

    // Books
    try {
      final legacyBooks = await _db
          .collection('users')
          .doc(legacyId)
          .collection('books')
          .get();
      debugPrint(
        '[OakShelf] restore: found ${legacyBooks.docs.length} book docs '
        'under $legacyId',
      );
      for (final doc in legacyBooks.docs) {
        try {
          await _userBooksRef.doc(doc.id).set(
                doc.data(),
                SetOptions(merge: true),
              );
          booksCopied++;
        } catch (e) {
          errors.add('Book ${doc.id}: ${_describeError(e)}');
        }
      }
    } catch (e) {
      errors.add('Could not READ old books: ${_describeError(e)}');
    }

    // Quotes
    try {
      final legacyQuotes = await _db
          .collection('users')
          .doc(legacyId)
          .collection('quotes')
          .get();
      debugPrint(
        '[OakShelf] restore: found ${legacyQuotes.docs.length} quote docs '
        'under $legacyId',
      );
      for (final doc in legacyQuotes.docs) {
        try {
          await _userQuotesRef
              .doc(doc.id)
              .set(doc.data(), SetOptions(merge: true));
          quotesCopied++;
        } catch (e) {
          errors.add('Quote ${doc.id}: ${_describeError(e)}');
        }
      }
    } catch (e) {
      errors.add('Could not READ old quotes: ${_describeError(e)}');
    }

    // Settings (goal + custom shelves): best effort only
    try {
      final challenge = await _db
          .collection('users')
          .doc(legacyId)
          .collection('settings')
          .doc('challenge')
          .get();
      if (challenge.exists && challenge.data() != null) {
        await _userSettingsRef
            .doc('challenge')
            .set(challenge.data()!, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[OakShelf] restore: goal copy skipped: $e');
    }
    try {
      final shelves = await _db
          .collection('users')
          .doc(legacyId)
          .collection('settings')
          .doc('custom_shelves')
          .get();
      if (shelves.exists) {
        final list = (shelves.data()?['shelves'] as List?) ?? const [];
        if (list.isNotEmpty) {
          await _userSettingsRef.doc('custom_shelves').set({
            'shelves': FieldValue.arrayUnion(list.cast<String>()),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('[OakShelf] restore: shelf names copy skipped: $e');
    }

    debugPrint(
      '[OakShelf] restore done: books=$booksCopied quotes=$quotesCopied '
      'errors=${errors.length}',
    );
    return RestoreResult(
      booksCopied: booksCopied,
      quotesCopied: quotesCopied,
      errors: errors,
    );
  }

  String _describeError(Object e) {
    if (e is FirebaseException) {
      return '${e.code}${e.message == null ? '' : ' - ${e.message}'}';
    }
    return e.toString();
  }
}

/// Outcome of [FirebaseService.restoreFromOwner].
class RestoreResult {
  final int booksCopied;
  final int quotesCopied;
  final List<String> errors;

  const RestoreResult({
    required this.booksCopied,
    required this.quotesCopied,
    this.errors = const [],
  });

  bool get ok => errors.isEmpty;
}
