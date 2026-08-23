import 'dart:async';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/firebase_service.dart';
import '../services/google_books_service.dart';
import '../theme/theme.dart';
import '../widgets/nature_ui.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const SearchScreen({
    super.key,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  Map<String, Book> _savedBooksMap = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  StreamSubscription<List<Book>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.firebaseService.getBookShelfStream().listen((books) {
      if (!mounted) return;
      setState(() {
        _savedBooksMap = {for (final book in books) book.id: book};
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await widget.apiService.searchBooks(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not search books: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Books')),
      body: NatureBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: NatureHeroCard(
                startColor: context.oak.ocean,
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your next escape',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Search the catalog by title, author, or genre.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.oak.sky,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _performSearch(),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search books...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            padding: EdgeInsets.zero,
                            backgroundColor: context.oak.accent,
                            foregroundColor: context.oak.onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? _buildPlaceholder()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final book = _searchResults[index];
                        return _buildSearchResultCard(
                          book,
                          _savedBooksMap[book.id],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: NatureEmptyState(
          icon: _hasSearched ? Icons.search_off_rounded : Icons.sailing_rounded,
          title: _hasSearched ? 'No books found' : 'Set sail for a new story',
          message: _hasSearched
              ? 'Try a different title, author, or broader keyword.'
              : 'Explore the catalog, then save discoveries to your reading garden.',
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(Book book, Book? savedBook) {
    final theme = Theme.of(context);
    final shelf = savedBook?.shelf ?? ShelfStatus.none;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openBookDetail(book),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NatureBookCover(
                imageUrl: book.thumbnailUrl,
                title: book.title,
                width: 70,
                height: 104,
                radius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authors.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (book.averageRating != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: context.oak.accent,
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            book.averageRating!.toStringAsFixed(1),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getYearFromDate(book.publishedDate),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (shelf != ShelfStatus.none)
                      _buildTag(
                        shelf.displayName,
                        theme.colorScheme.primary,
                        Colors.white,
                      )
                    else if (book.categories.isNotEmpty)
                      _buildTag(
                        book.categories.first,
                        theme.colorScheme.secondaryContainer,
                        theme.colorScheme.onSecondaryContainer,
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 38),
                child: Icon(Icons.chevron_right_rounded, size: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color background, Color foreground) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground, fontSize: 10),
      ),
    );
  }

  String _getYearFromDate(String date) {
    if (date.isEmpty) return 'Unknown year';
    return date.length >= 4 ? date.substring(0, 4) : date;
  }

  void _openBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          bookId: book.id,
          initialBook: book,
          firebaseService: widget.firebaseService,
          apiService: widget.apiService,
        ),
      ),
    );
  }
}
