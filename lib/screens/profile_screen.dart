import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/quote.dart';
import '../services/firebase_service.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseService firebaseService;

  const ProfileScreen({super.key, required this.firebaseService});

  // Calculate Reader Tier based on books completed
  String _getReaderTier(int completedCount) {
    if (completedCount <= 2) return 'Novice Reader';
    if (completedCount <= 7) return 'Avid Bibliophile';
    if (completedCount <= 15) return 'Literary Enthusiast';
    return 'Book Connoisseur';
  }

  // Calculate favorite genres based on saved books
  List<String> _getFavoriteGenres(List<Book> books) {
    final Map<String, int> genreCounts = {};
    for (var book in books) {
      for (var genre in book.categories) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }

    // Sort and get top 3
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedGenres.take(3).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reader Profile'), centerTitle: true),
      body: NatureBackdrop(
        child: StreamBuilder<List<Book>>(
          stream: firebaseService.getBookShelfStream(),
          builder: (context, bookSnapshot) {
            if (bookSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final books = bookSnapshot.data ?? [];
            final readBooks = books
                .where((b) => b.shelf == ShelfStatus.read)
                .toList();
            final readingBooks = books
                .where((b) => b.shelf == ShelfStatus.reading)
                .toList();

            // Calculate stats
            int totalPages = 0;
            double totalRating = 0.0;
            int ratedCount = 0;
            for (var book in readBooks) {
              totalPages += book.pageCount ?? 0;
              if (book.userRating > 0) {
                totalRating += book.userRating;
                ratedCount++;
              }
            }
            for (var book in readingBooks) {
              totalPages += book.currentPage; // Include in-progress pages
            }

            final avgRating = ratedCount > 0
                ? (totalRating / ratedCount).toStringAsFixed(1)
                : '—';
            final favoriteGenres = _getFavoriteGenres(books);

            return StreamBuilder<List<Quote>>(
              stream: firebaseService.getQuotesStream(),
              builder: (context, quoteSnapshot) {
                final quotesCount = (quoteSnapshot.data ?? []).length;
                final tier = _getReaderTier(readBooks.length);

                return StreamBuilder<int>(
                  stream: firebaseService.getReadingGoalStream(),
                  builder: (context, goalSnapshot) {
                    final goal = goalSnapshot.data ?? 12;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Header Card
                          _buildUserHeader(context, tier),
                          const SizedBox(height: 24),

                          // Grid Stats Card
                          _buildStatsGrid(
                            context,
                            readBooks.length,
                            totalPages,
                            avgRating,
                            quotesCount,
                          ),
                          const SizedBox(height: 24),

                          // Yearly Challenge Widget
                          _buildChallengeCard(context, readBooks.length, goal),
                          const SizedBox(height: 24),

                          // Favorite Genres
                          _buildGenresSection(context, favoriteGenres),
                          const SizedBox(height: 32),
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

  Widget _buildUserHeader(BuildContext context, String tier) {
    final theme = Theme.of(context);
    return NatureHeroCard(
      startColor: context.oak.forestDeep,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Styled Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.oak.accent, width: 2),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anonymous Reader',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tier,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.oak.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cloud library connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: context.oak.sky,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    int completed,
    int pages,
    String avgRating,
    int quotes,
  ) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          'Completed',
          completed.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Pages Read',
          pages.toString(),
          Icons.pages_outlined,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          'My Avg Rating',
          avgRating,
          Icons.star_border_rounded,
          Colors.amber[700]!,
        ),
        _buildStatCard(
          context,
          'Saved Quotes',
          quotes.toString(),
          Icons.format_quote_outlined,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, int completed, int goal) {
    final theme = Theme.of(context);
    final progress = (completed / goal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.military_tech_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '2026 Reading Challenge',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenge progress: $completed of $goal books completed',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.12,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresSection(BuildContext context, List<String> genres) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favorite Genres', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (genres.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Text(
              'Shelved books will automatically categorize your top genres here!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  genre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
