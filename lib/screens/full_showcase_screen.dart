import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import 'book_detail_screen.dart';

class FullShowcaseScreen extends StatefulWidget {
  final ShelfStatus shelfStatus;
  final String shelfTitle;
  final String? customShelfName;
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const FullShowcaseScreen({
    super.key,
    required this.shelfStatus,
    required this.shelfTitle,
    this.customShelfName,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<FullShowcaseScreen> createState() => _FullShowcaseScreenState();
}

class _FullShowcaseScreenState extends State<FullShowcaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shelfTitle),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Book>>(
        stream: widget.firebaseService.getBookShelfStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBooks = snapshot.data ?? [];
          final shelfBooks = widget.customShelfName != null
              ? allBooks.where((b) => b.customShelves.contains(widget.customShelfName)).toList()
              : allBooks.where((b) => b.shelf == widget.shelfStatus).toList();

          return ValueListenableBuilder<String>(
            valueListenable: _searchQueryNotifier,
            builder: (context, searchQuery, _) {
              final filteredBooks = shelfBooks.where((book) {
                if (searchQuery.trim().isEmpty) return true;
                final q = searchQuery.toLowerCase();
                final titleMatch = book.title.toLowerCase().contains(q);
                final authorMatch = book.authors.any((a) => a.toLowerCase().contains(q));
                return titleMatch || authorMatch;
              }).toList();

              return Column(
                children: [
                  // Dedicated Search Bar inside Full Showcase
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search in ${widget.shelfTitle}...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQueryNotifier.value = '';
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.primary.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        _searchQueryNotifier.value = val;
                      },
                    ),
                  ),

                  // Header Counter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filteredBooks.length} of ${shelfBooks.length} books',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Showcase Grid
                  Expanded(
                    child: filteredBooks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                searchQuery.isNotEmpty
                                    ? 'No books matching "$searchQuery" in ${widget.shelfTitle}'
                                    : 'No books in ${widget.shelfTitle} yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.44, // Tall aspect ratio to fit book image + text cleanly
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 18,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              final totalPages = book.pageCount ?? 0;
                              final currentPgs = book.currentPage;
                              final progress = totalPages > 0 ? (currentPgs / totalPages).clamp(0.0, 1.0) : 0.0;
                              final percent = (progress * 100).toInt();

                              return GestureDetector(
                                onTap: () => _openBookDetail(book),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // True 1:1.48 Book Cover Ratio Container
                                    AspectRatio(
                                      aspectRatio: 1 / 1.48,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Stack(
                                            children: [
                                              book.thumbnailUrl.isNotEmpty
                                                  ? Image.network(
                                                      book.thumbnailUrl,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: const Color(0xFF2F3E46),
                                                        child: const Center(
                                                          child: Icon(Icons.book, size: 36, color: Colors.white54),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(color: const Color(0xFF2F3E46)),
                                              Positioned(
                                                left: 0, top: 0, bottom: 0, width: 5,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      book.authors.join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (widget.shelfStatus == ShelfStatus.reading) ...[
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$percent%',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9.5,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ] else if (book.userRating > 0 || (book.averageRating != null && book.averageRating! > 0)) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                          const SizedBox(width: 3),
                                          Text(
                                            book.userRating > 0
                                                ? book.userRating.toStringAsFixed(1)
                                                : book.averageRating!.toStringAsFixed(1),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
