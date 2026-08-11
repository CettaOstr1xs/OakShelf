import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_menu_sheet.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';
import 'book_detail_screen.dart';
import 'reading_challenge_screen.dart';
import 'full_showcase_screen.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const HomeScreen({
    super.key,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(
    List<Book> books,
    ShelfStatus status,
    String searchQuery,
  ) {
    return books.where((book) {
      if (book.shelf != status) return false;
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      final titleMatch = book.title.toLowerCase().contains(q);
      final authorMatch = book.authors.any((a) => a.toLowerCase().contains(q));
      return titleMatch || authorMatch;
    }).toList();
  }

  List<Book> _filterCustomBooks(
    List<Book> books,
    String customShelfName,
    String searchQuery,
  ) {
    return books.where((book) {
      if (!book.customShelves.contains(customShelfName)) return false;
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      final titleMatch = book.title.toLowerCase().contains(q);
      final authorMatch = book.authors.any((a) => a.toLowerCase().contains(q));
      return titleMatch || authorMatch;
    }).toList();
  }

  void _openReadingChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingChallengeScreen(
          firebaseService: widget.firebaseService,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  void _openFullShowcase(
    ShelfStatus status,
    String title, {
    String? customShelfName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullShowcaseScreen(
          shelfStatus: status,
          shelfTitle: title,
          customShelfName: customShelfName,
          firebaseService: widget.firebaseService,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  void _openCreateBookshelfDialog() {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Bookshelf',
      barrierColor: Colors.black.withOpacity(0.54),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor:
                  theme.colorScheme.background, // Same color as page background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Create New Bookshelf'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter a custom name for your new bookshelf collection:',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Bookshelf Name',
                      hintText: 'e.g. Favorites, Sci-Fi, Classics',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final shelfName = controller.text.trim();
                    if (shelfName.isNotEmpty) {
                      await widget.firebaseService.createCustomShelf(shelfName);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Custom bookshelf "$shelfName" created!',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Bookshelf'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCustomShelf(String shelfName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "$shelfName"?'),
        content: Text(
          'Are you sure you want to delete the custom bookshelf "$shelfName"? Books inside will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.firebaseService.deleteCustomShelf(shelfName);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Shelf'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        centerTitle: true,
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
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const NatureErrorState(
                title: 'Your library could not load',
                message:
                    'Bookery could not read your saved books. Check your connection or Firebase setup, then try again.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allBooks = snapshot.data ?? [];
            final finishedCount = allBooks
                .where((b) => b.shelf == ShelfStatus.read)
                .length;

            return StreamBuilder<List<String>>(
              stream: widget.firebaseService.getCustomShelvesStream(),
              builder: (context, customSnapshot) {
                if (customSnapshot.hasError) {
                  return const NatureErrorState(
                    title: 'Custom shelves are unavailable',
                    message:
                        'Your standard shelves are safe, but custom shelf data could not be loaded.',
                  );
                }

                final customShelves = customSnapshot.data ?? [];

                return ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, searchQuery, _) {
                    final readingBooks = _filterBooks(
                      allBooks,
                      ShelfStatus.reading,
                      searchQuery,
                    );
                    final wantToReadBooks = _filterBooks(
                      allBooks,
                      ShelfStatus.wantToRead,
                      searchQuery,
                    );
                    final readBooks = _filterBooks(
                      allBooks,
                      ShelfStatus.read,
                      searchQuery,
                    );

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your reading garden',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep every story you are growing in one place.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),

                          // Bookshelf Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search my bookshelf by title or author...',
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
                              fillColor: BookeryTheme.surfaceColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              _searchQueryNotifier.value = val;
                            },
                          ),
                          const SizedBox(height: 18),

                          // READING CHALLENGE BANNER CONTAINER
                          StreamBuilder<int>(
                            stream: widget.firebaseService
                                .getReadingGoalStream(),
                            builder: (context, goalSnapshot) {
                              final goal = goalSnapshot.data ?? 12;
                              final progress = (finishedCount / goal).clamp(
                                0.0,
                                1.0,
                              );
                              final percent = (progress * 100).toInt();

                              return NatureHeroCard(
                                startColor: BookeryTheme.oceanBlueColor,
                                endColor: BookeryTheme.primaryColor,
                                onTap: _openReadingChallenge,
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.emoji_events_rounded,
                                              color:
                                                  BookeryTheme.accentGoldColor,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '2026 Reading Challenge',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$finishedCount of $goal books completed',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: BookeryTheme.skyColor,
                                              ),
                                        ),
                                        Text(
                                          '$percent%',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: BookeryTheme
                                                    .accentGoldColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              BookeryTheme.accentGoldColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // STANDARD SHELF SECTIONS
                          _buildShelfSection(
                            context: context,
                            title: 'Reading Now',
                            books: readingBooks,
                            shelfStatus: ShelfStatus.reading,
                            icon: Icons.menu_book_rounded,
                            isReadingShelf: true,
                            searchQuery: searchQuery,
                          ),
                          const SizedBox(height: 28),
                          _buildShelfSection(
                            context: context,
                            title: 'Wishlist (Want to Read)',
                            books: wantToReadBooks,
                            shelfStatus: ShelfStatus.wantToRead,
                            icon: Icons.bookmark_add_rounded,
                            isReadingShelf: false,
                            searchQuery: searchQuery,
                          ),
                          const SizedBox(height: 28),
                          _buildShelfSection(
                            context: context,
                            title: 'Finished Books',
                            books: readBooks,
                            shelfStatus: ShelfStatus.read,
                            icon: Icons.library_add_check_rounded,
                            isReadingShelf: false,
                            showRatings: true,
                            searchQuery: searchQuery,
                          ),

                          // USER CUSTOM CREATED BOOKSHELVES
                          if (customShelves.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_special_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'My Custom Bookshelves',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...customShelves.map((shelfName) {
                              final customBooks = _filterCustomBooks(
                                allBooks,
                                shelfName,
                                searchQuery,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 28.0),
                                child: _buildCustomShelfSection(
                                  context: context,
                                  shelfName: shelfName,
                                  books: customBooks,
                                  searchQuery: searchQuery,
                                ),
                              );
                            }).toList(),
                          ],

                          const SizedBox(height: 20),

                          // CREATE NEW BOOKSHELF BUTTON (Positioned at the bottom of the page)
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _openCreateBookshelfDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create New Bookshelf'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.4,
                                  ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildShelfSection({
    required BuildContext context,
    required String title,
    required List<Book> books,
    required ShelfStatus shelfStatus,
    required IconData icon,
    required bool isReadingShelf,
    required String searchQuery,
    bool showRatings = false,
  }) {
    final theme = Theme.of(context);
    final double shelfHeight = isReadingShelf
        ? 315.0
        : (showRatings ? 272.0 : 256.0);

    final int maxLimit = 5;
    final displayBooks = books.take(maxLimit).toList();
    final bool hasMore = books.length > maxLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openFullShowcase(shelfStatus, title),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          books.length.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      'See All',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (books.isEmpty)
          _buildEmptyShelfPlaceholder(context, searchQuery)
        else
          SizedBox(
            height: shelfHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayBooks.length + (hasMore ? 1 : 0),
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                if (index == displayBooks.length) {
                  return GestureDetector(
                    onTap: () => _openFullShowcase(shelfStatus, title),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 16),
                      child: AspectRatio(
                        aspectRatio: 1 / 1.48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(
                                0.25,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'See All',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${books.length} Books)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final book = displayBooks[index];
                final totalPages = book.pageCount ?? 0;
                final currentPgs = book.currentPage;
                final progress = totalPages > 0
                    ? (currentPgs / totalPages).clamp(0.0, 1.0)
                    : 0.0;
                final percent = (progress * 100).toInt();

                return GestureDetector(
                  onTap: () => _openBookDetail(context, book.id, book),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1 / 1.48,
                          child: NatureBookCover(
                            imageUrl: book.thumbnailUrl,
                            title: book.title,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.authors.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isReadingShelf) ...[
                          const SizedBox(height: 6),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$percent%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                totalPages > 0
                                    ? '$currentPgs/$totalPages'
                                    : 'pg $currentPgs',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (showRatings && book.userRating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                book.userRating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCustomShelfSection({
    required BuildContext context,
    required String shelfName,
    required List<Book> books,
    required String searchQuery,
  }) {
    final theme = Theme.of(context);
    final double shelfHeight = 256.0;

    final int maxLimit = 5;
    final displayBooks = books.take(maxLimit).toList();
    final bool hasMore = books.length > maxLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => _openFullShowcase(
                ShelfStatus.none,
                shelfName,
                customShelfName: shelfName,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shelfName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      books.length.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: Colors.grey[400],
                  tooltip: 'Delete Bookshelf',
                  onPressed: () => _confirmDeleteCustomShelf(shelfName),
                ),
                InkWell(
                  onTap: () => _openFullShowcase(
                    ShelfStatus.none,
                    shelfName,
                    customShelfName: shelfName,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (books.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Text(
                'No books in "$shelfName" yet. Tap any book to assign it!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: shelfHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayBooks.length + (hasMore ? 1 : 0),
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                if (index == displayBooks.length) {
                  return GestureDetector(
                    onTap: () => _openFullShowcase(
                      ShelfStatus.none,
                      shelfName,
                      customShelfName: shelfName,
                    ),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 16),
                      child: AspectRatio(
                        aspectRatio: 1 / 1.48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(
                                0.25,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'See All',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${books.length} Books)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final book = displayBooks[index];

                return GestureDetector(
                  onTap: () => _openBookDetail(context, book.id, book),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1 / 1.48,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.book,
                                                        size: 40,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                  ),
                                        )
                                      : Container(
                                          color: theme.colorScheme.primary,
                                          child: const Center(
                                            child: Icon(
                                              Icons.book,
                                              size: 40,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 6,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.35),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.authors.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildEmptyShelfPlaceholder(BuildContext context, String searchQuery) {
    return NatureEmptyState(
      icon: searchQuery.isNotEmpty
          ? Icons.search_off_rounded
          : Icons.local_florist_rounded,
      title: searchQuery.isNotEmpty
          ? 'No matching books'
          : 'This shelf is ready to grow',
      message: searchQuery.isNotEmpty
          ? 'No books match "$searchQuery" in this shelf.'
          : 'Add a book from search to begin this collection.',
    );
  }

  void _openBookDetail(BuildContext context, String bookId, Book initialBook) {
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
}
