import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/book.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import 'book_detail_screen.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';

class ReadingChallengeScreen extends StatefulWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService? apiService;

  const ReadingChallengeScreen({
    super.key,
    required this.firebaseService,
    this.apiService,
  });

  @override
  State<ReadingChallengeScreen> createState() => _ReadingChallengeScreenState();
}

class _ReadingChallengeScreenState extends State<ReadingChallengeScreen> {
  void _openSetGoalDialog(int currentGoal) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set 2026 Reading Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many books do you want to read this year?'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Books',
                suffixText: 'books',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
            onPressed: () {
              final newGoal =
                  int.tryParse(controller.text.trim()) ?? currentGoal;
              if (newGoal > 0) {
                widget.firebaseService.saveReadingGoal(newGoal);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }

  void _openBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          bookId: book.id,
          initialBook: book,
          firebaseService: widget.firebaseService,
          apiService: widget.apiService ?? GoogleBooksService(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('2026 Reading Challenge'),
        centerTitle: true,
      ),
      body: NatureBackdrop(
        child: StreamBuilder<List<Book>>(
          stream: widget.firebaseService.getBookShelfStream(),
          builder: (context, bookSnapshot) {
            final books = bookSnapshot.data ?? [];
            final finishedBooks = books
                .where((b) => b.shelf == ShelfStatus.read)
                .toList();

            return StreamBuilder<int>(
              stream: widget.firebaseService.getReadingGoalStream(),
              builder: (context, goalSnapshot) {
                final goal = goalSnapshot.data ?? 12;
                final completedCount = finishedBooks.length;
                final progress = goal > 0
                    ? (completedCount / goal).clamp(0.0, 1.0)
                    : 0.0;
                final percent = (progress * 100).toInt();
                final booksLeft = (goal - completedCount).clamp(0, 999);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Challenge Progress Card
                      NatureHeroCard(
                        startColor: context.oak.forestDeep,
                        endColor: context.oak.ocean,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_rounded,
                                      color: context.oak.accent,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ANNUAL GOAL',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: context.oak.sky,
                                          ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  color: Colors.white,
                                  tooltip: 'Adjust Goal',
                                  onPressed: () => _openSetGoalDialog(goal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Circular Progress Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.18,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.oak.accent,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '$completedCount / $goal',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                    Text(
                                      'Books Read',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.oak.sky,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Text(
                              completedCount >= goal
                                  ? '🎉 Congratulations! You completed your 2026 challenge!'
                                  : '$booksLeft more ${booksLeft == 1 ? "book" : "books"} to reach your goal ($percent% completed)',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 28),

                      // Milestone Badges Section
                      Text(
                        'Milestones & Badges',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBadgeChip(
                            icon: Icons.menu_book_rounded,
                            title: 'First Step',
                            subtitle: '1 Book',
                            isUnlocked: completedCount >= 1,
                          ),
                          _buildBadgeChip(
                            icon: Icons.auto_stories_rounded,
                            title: 'Avid Reader',
                            subtitle: '5 Books',
                            isUnlocked: completedCount >= 5,
                          ),
                          _buildBadgeChip(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Champion',
                            subtitle: '$goal Goal',
                            isUnlocked: completedCount >= goal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Finished Books Grid
                      Text(
                        'Finished Books for Challenge ($completedCount)',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),

                      if (finishedBooks.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme.surfaceContainerLowest
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.library_books_rounded,
                                size: 40,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No finished books logged yet.',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mark books as "Finished" in your bookshelf to count towards your challenge!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.44,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 18,
                              ),
                          itemCount: finishedBooks.length,
                          itemBuilder: (context, index) {
                            final book = finishedBooks[index];
                            return GestureDetector(
                              onTap: () => _openBookDetail(book),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1 / 1.48,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.12,
                                            ),
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
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons.book,
                                                              size: 36,
                                                              color: Colors
                                                                  .white54,
                                                            ),
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 5,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.black.withOpacity(
                                                        0.35,
                                                      ),
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
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        book.userRating > 0
                                            ? book.userRating.toStringAsFixed(1)
                                            : (book.averageRating != null &&
                                                      book.averageRating! > 0
                                                  ? book.averageRating!
                                                        .toStringAsFixed(1)
                                                  : 'Unrated'),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadgeChip({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnlocked,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isUnlocked ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isUnlocked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked
                  ? theme.colorScheme.primary.withOpacity(0.8)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
