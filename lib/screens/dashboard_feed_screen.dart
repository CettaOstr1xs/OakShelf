import 'dart:math';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/quote.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_menu_sheet.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';
import 'book_detail_screen.dart';

class DashboardFeedScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const DashboardFeedScreen({
    super.key,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<DashboardFeedScreen> createState() => _DashboardFeedScreenState();
}

class _DashboardFeedScreenState extends State<DashboardFeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep feed tab state alive so switching tabs never reloads!

  // Catalog of inspirational quotes
  final List<Map<String, String>> _quoteCollection = [
    {
      'text': 'A room without books is like a body without a soul.',
      'author': 'Marcus Tullius Cicero',
    },
    {
      'text': 'There is no friend as loyal as a book.',
      'author': 'Ernest Hemingway',
    },
    {
      'text': 'I have always imagined that Paradise will be a kind of library.',
      'author': 'Jorge Luis Borges',
    },
    {'text': 'Books are a uniquely portable magic.', 'author': 'Stephen King'},
    {
      'text': 'Reading is departure and arrival, the start and the final goal.',
      'author': 'Hugo von Hofmannsthal',
    },
    {
      'text':
          'You can never get a cup of tea large enough or a book long enough to suit me.',
      'author': 'C.S. Lewis',
    },
    {
      'text': 'We read to know we\'re not alone.',
      'author': 'William Nicholson',
    },
    {
      'text':
          'If you only read the books that everyone else is reading, you can only think what everyone else is thinking.',
      'author': 'Haruki Murakami',
    },
    {
      'text':
          'It is what you read when you don\'t have to that determines what you will be when you can\'t help it.',
      'author': 'Oscar Wilde',
    },
    {
      'text':
          'The mind is not a vessel to be filled, but a fire to be kindled.',
      'author': 'Plutarch',
    },
    {
      'text':
          'You have power over your mind - not outside events. Realize this, and you will find strength.',
      'author': 'Marcus Aurelius',
    },
    {
      'text':
          'In the depth of winter, I finally learned that within me there lay an invincible summer.',
      'author': 'Albert Camus',
    },
    {
      'text': 'A book must be the axe for the frozen sea within us.',
      'author': 'Franz Kafka',
    },
    {
      'text':
          'Life isn\'t about finding yourself. Life is about creating yourself.',
      'author': 'George Bernard Shaw',
    },
    {
      'text':
          'The reading of all good books is like a conversation with the finest minds of past centuries.',
      'author': 'René Descartes',
    },
    {'text': 'Beware of the person of one book.', 'author': 'Thomas Aquinas'},
    {
      'text':
          'Until I feared I would lose it, I never loved reading. One does not love breathing.',
      'author': 'Harper Lee',
    },
    {'text': 'So many books, so little time.', 'author': 'Frank Zappa'},
    {
      'text':
          'The world is a book and those who do not travel read only one page.',
      'author': 'St. Augustine',
    },
    {
      'text':
          'Books serve to show a man that those original thoughts of his aren\'t very new after all.',
      'author': 'Abraham Lincoln',
    },
  ];

  Map<String, String> _chosenQuote = {};
  bool _isSavingQuote = false;
  bool _isQuoteSaved = false;

  // Recommendation engine state
  List<Book> _recommendedBooks = [];
  bool _isLoadingRecommendations = false;
  bool _hasAttemptedRecommendations = false;

  @override
  void initState() {
    super.initState();
    _randomizeQuote();
  }

  void _randomizeQuote() {
    final random = Random();
    setState(() {
      _chosenQuote = _quoteCollection[random.nextInt(_quoteCollection.length)];
      _isQuoteSaved = false;
    });
  }

  Future<void> _saveCurrentQuote() async {
    if (_chosenQuote['text'] == null || _isQuoteSaved) return;
    setState(() {
      _isSavingQuote = true;
    });

    try {
      final newQuote = Quote(
        id: '',
        quoteText: _chosenQuote['text']!,
        author: _chosenQuote['author'] ?? 'Unknown Author',
        bookTitle: 'Daily Inspiration',
        dateAdded: DateTime.now(),
      );

      await widget.firebaseService.saveQuote(newQuote);

      if (mounted) {
        setState(() {
          _isQuoteSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quote saved to your library!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingQuote = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendationsOnce(List<Book> eligibleBooks) async {
    if (_hasAttemptedRecommendations || _isLoadingRecommendations) return;
    _hasAttemptedRecommendations = true;

    setState(() {
      _isLoadingRecommendations = true;
    });

    final recs = await widget.apiService.fetchBookRecommendations(
      eligibleBooks,
    );

    if (mounted) {
      setState(() {
        _recommendedBooks = recs;
        _isLoadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dateStr = _formatDate(today);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 20, color: BookeryTheme.primaryColor),
            SizedBox(width: 7),
            Text('Bookery'),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => showProfileMenuSheet(
              context: context,
              firebaseService: widget.firebaseService,
              apiService: widget.apiService,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: NatureBackdrop(
        child: StreamBuilder<List<Book>>(
          stream: widget.firebaseService.getBookShelfStream(),
          builder: (context, bookSnapshot) {
            final books = bookSnapshot.data ?? [];
            final readingBooks = books
                .where((b) => b.shelf == ShelfStatus.reading)
                .toList();
            final readBooks = books
                .where((b) => b.shelf == ShelfStatus.read)
                .toList();
            final wantBooks = books
                .where((b) => b.shelf == ShelfStatus.wantToRead)
                .toList();

            final eligibleBooks = [...readBooks, ...wantBooks];
            final hasThreeEligible = eligibleBooks.length >= 3;

            if (hasThreeEligible && !_hasAttemptedRecommendations) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchRecommendationsOnce(eligibleBooks);
              });
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Welcome Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A fresh page awaits',
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: BookeryTheme.sandColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BookeryTheme.accentGoldColor,
                          ),
                        ),
                        child: const Icon(
                          Icons.wb_sunny_rounded,
                          color: Color(0xFF9A6D00),
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Daily Inspiration Quote Card
                  _buildQuoteInspirationCard(_chosenQuote),
                  const SizedBox(height: 24),

                  // Summary Stats Dashboard
                  _buildStatsRow(
                    books.length,
                    readingBooks.length,
                    readBooks.length,
                    wantBooks.length,
                  ),
                  const SizedBox(height: 28),

                  // Currently Reading Section
                  _buildCurrentlyReadingSection(readingBooks),
                  const SizedBox(height: 32),

                  // Book Recommendations Section (Below Currently Reading)
                  _buildRecommendationsSection(
                    hasThreeEligible,
                    eligibleBooks.length,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuoteInspirationCard(Map<String, String> quote) {
    final theme = Theme.of(context);

    return NatureHeroCard(
      startColor: BookeryTheme.forestDeep,
      endColor: BookeryTheme.oceanBlueColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: BookeryTheme.accentGoldColor,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY INSPIRATION',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: _isSavingQuote
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isQuoteSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_add_outlined,
                              size: 22,
                              color: _isQuoteSaved
                                  ? BookeryTheme.accentGoldColor
                                  : Colors.white,
                            ),
                      tooltip: _isQuoteSaved ? 'Quote Saved' : 'Save Quote',
                      onPressed: _saveCurrentQuote,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                      color: Colors.white,
                      tooltip: 'New Random Quote',
                      onPressed: _randomizeQuote,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"${quote['text']}"',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.normal,
                height: 1.45,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '— ${quote['author']}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: BookeryTheme.skyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int total, int reading, int read, int want) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: BookeryTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BookeryTheme.outlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Logged',
                  total.toString(),
                  Icons.library_books_rounded,
                  theme.colorScheme.primary,
                ),
                _buildStatDivider(),
                _buildStatColumn(
                  'Reading',
                  reading.toString(),
                  Icons.auto_stories_rounded,
                  theme.colorScheme.secondary,
                ),
                _buildStatDivider(),
                _buildStatColumn(
                  'Finished',
                  read.toString(),
                  Icons.check_circle_rounded,
                  const Color(0xFF9A6D00),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            count,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 35, color: Colors.grey[200]);
  }

  Widget _buildCurrentlyReadingSection(List<Book> readingBooks) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currently Reading', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        if (readingBooks.isEmpty)
          const NatureEmptyState(
            icon: Icons.menu_book_rounded,
            title: 'Your summer reading spot is open',
            message:
                'Use the search button below to find a book and begin reading.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readingBooks.length,
            itemBuilder: (context, index) {
              final book = readingBooks[index];
              final total = book.pageCount ?? 0;
              final current = book.currentPage;
              final progress = total > 0
                  ? (current / total).clamp(0.0, 1.0)
                  : 0.0;
              final percent = (progress * 100).toInt();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openBookDetail(book.id, book),
                        child: Container(
                          width: 60,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: NatureBookCover(
                            imageUrl: book.thumbnailUrl,
                            title: book.title,
                            width: 60,
                            height: 90,
                            radius: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openBookDetail(book.id, book),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                book.authors.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),

                              if (total > 0) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$percent% completed',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      '$current/$total pgs',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                        onPressed: () => _openBookDetail(book.id, book),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Book Recommendations Container (Unlocks at 10+ Wishlist or Finished Books)
  Widget _buildRecommendationsSection(
    bool hasThreeEligible,
    int eligibleCount,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Recommended Books for You',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (!hasThreeEligible) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  size: 36,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'Unlock Book Recommendations',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add at least 3 books to your Wishlist or Finished shelf to unlock diverse book recommendations tailored to your taste.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (eligibleCount / 3.0).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.12,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$eligibleCount / 3 books logged',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_isLoadingRecommendations) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_recommendedBooks.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No book recommendations found right now.',
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          SizedBox(
            height: 265,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedBooks.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final recBook = _recommendedBooks[index];
                final ratingStr = recBook.averageRating != null
                    ? recBook.averageRating!.toStringAsFixed(1)
                    : null;

                return GestureDetector(
                  onTap: () => _openBookDetail(recBook.id, recBook),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
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
                                  child: recBook.thumbnailUrl.isNotEmpty
                                      ? Image.network(
                                          recBook.thumbnailUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.book,
                                                        size: 36,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                  ),
                                        )
                                      : Container(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                ),
                              ),
                            ),
                            if (ratingStr != null)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        ratingStr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recBook.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recBook.authors.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openBookDetail(String bookId, [Book? initialBook]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          bookId: bookId,
          initialBook: initialBook,
          firebaseService: widget.firebaseService,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
