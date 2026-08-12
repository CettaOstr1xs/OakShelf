import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/quote.dart';
import '../models/author.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import '../services/hardcover_service.dart';
import '../services/author_service.dart';
import '../widgets/interactive_book_cover_modal.dart';
import '../widgets/nature_ui.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  final Book? initialBook;
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.initialBook,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _localBook;
  bool _isLoading = true;
  bool _anyChanges = false;
  bool _isDescriptionExpanded = false;

  late TextEditingController _reviewController;
  late TextEditingController _progressController;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _progressController = TextEditingController();

    if (widget.initialBook != null) {
      _localBook = widget.initialBook;
      _isLoading = false;
      _reviewController.text = _localBook!.userReview;
      _progressController.text = _localBook!.currentPage > 0
          ? _localBook!.currentPage.toString()
          : '';
    }

    _loadBookDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetails() async {
    if (_localBook == null) {
      setState(() => _isLoading = true);
    }

    // 1. Try loading from Firestore first
    Book? book = await widget.firebaseService.getBook(widget.bookId);

    // 2. If not found in user library, query from Google Books API
    if (book == null) {
      book = await widget.apiService.getBookDetails(widget.bookId);
    }

    if (book != null) {
      setState(() {
        _localBook = book;
        _reviewController.text = book!.userReview;
        _progressController.text = book!.currentPage.toString();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load book details.')),
      );
    }
  }

  // Sanitizes raw HTML strings from Google Books description
  String _cleanDescription(String htmlString) {
    if (htmlString.isEmpty) return 'No description available.';
    String clean = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    clean = clean
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'");
    return clean;
  }

  Future<void> _saveChanges() async {
    if (_localBook == null) return;

    // Sync controllers to model
    _localBook!.userReview = _reviewController.text;
    final progress = int.tryParse(_progressController.text) ?? 0;
    final total = _localBook!.pageCount ?? 0;
    _localBook!.currentPage = progress.clamp(0, total > 0 ? total : progress);

    await widget.firebaseService.saveBook(_localBook!);

    setState(() {
      _anyChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity saved to Cloud Firestore!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openAddQuoteFromBookSheet() {
    if (_localBook == null) return;
    final theme = Theme.of(context);
    final quoteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Quote from Book',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quote source: ${_localBook!.title} by ${_localBook!.authors.first}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: quoteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Quote Text',
                      hintText: '"Enter wholesomeness or inspiring lines..."',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Quote text is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final quote = Quote(
                            id: '',
                            quoteText: quoteController.text.trim(),
                            author: _localBook!.authors.first,
                            bookTitle: _localBook!.title,
                            dateAdded: DateTime.now(),
                          );
                          await widget.firebaseService.saveQuote(quote);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quote logged to collection!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Save Quote',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _anyChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _anyChanges);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _localBook == null
            ? const Center(child: Text('Book details could not be found.'))
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: NatureBackdrop(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookIdentitySection(),
                        const SizedBox(height: 24),
                        _buildMetadataRow(),
                        const SizedBox(height: 20),
                        _buildSynopsisSection(),
                        _buildGenresAndMoodsSection(),
                        const Divider(height: 40, thickness: 1),
                        _buildUserActivitySection(),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                   ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBookIdentitySection() {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (_localBook != null) {
              InteractiveBookCoverModal.show(
                context: context,
                heroTag: 'book_cover_${_localBook!.id}',
                thumbnailUrl: _localBook!.thumbnailUrl,
                title: _localBook!.title,
                author: _localBook!.authors.join(', '),
              );
            }
          },
          child: Hero(
            tag: 'book_cover_${_localBook!.id}',
            child: NatureBookCover(
              imageUrl: _localBook!.thumbnailUrl,
              title: _localBook!.title,
              width: 110,
              height: 160,
              radius: 8,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                _localBook!.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'By ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.8),
                    ),
                  ),
                  ..._localBook!.authors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final author = entry.value;
                    final isLast = index == _localBook!.authors.length - 1;
                    return InkWell(
                      onTap: () => _showAuthorDetails(author),
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        '$author${isLast ? "" : ", "}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              if (_localBook!.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localBook!.categories.first,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow() {
    final theme = Theme.of(context);
    final year = _localBook!.publishedDate.isNotEmpty
        ? (_localBook!.publishedDate.length >= 4
              ? _localBook!.publishedDate.substring(0, 4)
              : _localBook!.publishedDate)
        : 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetadataItem(
            value: _localBook!.averageRating != null
                ? _localBook!.averageRating!.toStringAsFixed(1)
                : '—',
            label: 'Catalog Rating',
            icon: Icons.star_rounded,
            iconColor: Colors.amber[600]!,
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildMetadataItem(
            value: _localBook!.pageCount != null
                ? '${_localBook!.pageCount}'
                : '—',
            label: 'Pages',
            icon: Icons.auto_stories_rounded,
            iconColor: theme.colorScheme.primary,
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildMetadataItem(
            value: year,
            label: 'Published',
            icon: Icons.calendar_today_rounded,
            iconColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSynopsisSection() {
    final theme = Theme.of(context);
    final cleanDesc = _cleanDescription(_localBook!.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Text(
            cleanDesc,
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ),
        if (cleanDesc.length > 200)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isDescriptionExpanded ? 'Show Less' : 'Read Full Synopsis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserActivitySection() {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Activity Log',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Shelf Selection
            Text('Shelf Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildShelfChip(
                  ShelfStatus.reading,
                  Icons.play_circle_filled_rounded,
                ),
                _buildShelfChip(
                  ShelfStatus.wantToRead,
                  Icons.bookmark_added_rounded,
                ),
                _buildShelfChip(ShelfStatus.read, Icons.check_circle_rounded),
              ],
            ),
            const SizedBox(height: 12),

            // Custom Bookshelves Section
            StreamBuilder<List<String>>(
              stream: widget.firebaseService.getCustomShelvesStream(),
              builder: (context, snapshot) {
                final customShelves = snapshot.data ?? [];
                if (customShelves.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Custom Shelves',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: customShelves.map((shelfName) {
                        final isSelected = _localBook!.customShelves.contains(
                          shelfName,
                        );
                        return FilterChip(
                          label: Text(shelfName),
                          avatar: Icon(
                            Icons.folder_special_rounded,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!_localBook!.customShelves.contains(
                                  shelfName,
                                )) {
                                  _localBook!.customShelves.add(shelfName);
                                }
                              } else {
                                _localBook!.customShelves.remove(shelfName);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Progress Log (Only for Reading)
            if (_localBook!.shelf == ShelfStatus.reading) ...[
              _buildProgressInputSection(),
              const SizedBox(height: 16),
            ],

            // Star Rating
            Text('My Rating', style: theme.textTheme.titleSmall),
            _buildInteractiveStars(),
            const SizedBox(height: 12),

            // Text Review
            Text('My Review', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this book...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Add Quote from Book Shortcut
            Center(
              child: TextButton.icon(
                onPressed: _openAddQuoteFromBookSheet,
                icon: const Icon(Icons.format_quote_rounded),
                label: const Text('Add Quote from this Book'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),

            if (_localBook!.dateAdded != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Added on ${_formatDate(_localBook!.dateAdded!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShelfChip(ShelfStatus status, IconData icon) {
    final isSelected = _localBook!.shelf == status;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(status.displayName),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
      ),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _localBook!.shelf = selected ? status : ShelfStatus.none;
          if (_localBook!.shelf != ShelfStatus.reading) {
            _progressController.text = '0';
          } else if (_localBook!.shelf == ShelfStatus.read &&
              _localBook!.pageCount != null) {
            _progressController.text = _localBook!.pageCount.toString();
          }
        });
      },
    );
  }

  Widget _buildProgressInputSection() {
    final theme = Theme.of(context);
    final totalPages = _localBook!.pageCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          const Text('Currently on Page: '),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            height: 38,
            child: TextField(
              controller: _progressController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final page = int.tryParse(val) ?? 0;
                if (totalPages > 0 && page > totalPages) {
                  _progressController.text = totalPages.toString();
                  _progressController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _progressController.text.length),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(totalPages > 0 ? 'of $totalPages' : 'pages'),
        ],
      ),
    );
  }

  Widget _buildInteractiveStars() {
    final rating = _localBook!.userRating;
    const double starSize = 38.0;
    const double starPadding = 8.0; // 4.0 on left + 4.0 on right
    const double singleStarWidth = starSize + starPadding; // 46.0
    const double totalRowWidth = singleStarWidth * 5; // 230.0

    void updateRatingFromDx(double dx) {
      final clampedDx = dx.clamp(0.0, totalRowWidth);
      final rawRating = (clampedDx / totalRowWidth) * 5.0;
      double newRating = (rawRating * 2).round() / 2.0;
      if (newRating < 0.5) newRating = 0.5;
      if (newRating > 5.0) newRating = 5.0;
      setState(() {
        _localBook!.userRating = newRating;
      });
    }

    return Column(
      children: [
        GestureDetector(
          onTapDown: (details) => updateRatingFromDx(details.localPosition.dx),
          onPanStart: (details) => updateRatingFromDx(details.localPosition.dx),
          onPanUpdate: (details) =>
              updateRatingFromDx(details.localPosition.dx),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                IconData iconData;
                if (rating >= starIndex) {
                  iconData = Icons.star_rounded;
                } else if (rating >= starIndex - 0.5) {
                  iconData = Icons.star_half_rounded;
                } else {
                  iconData = Icons.star_border_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    iconData,
                    color: const Color(0xFFF2CC8F),
                    size: starSize,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rating > 0
              ? '${rating.toStringAsFixed(1)} Stars (Slide left/right to adjust)'
              : 'Slide left or right to rate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildGenresAndMoodsSection() {
    final theme = Theme.of(context);
    final tags = HardcoverService.getGenresAndMoodsSync(
      title: _localBook!.title,
      authors: _localBook!.authors,
      categories: _localBook!.categories,
      description: _localBook!.description,
    );

    if (tags.genres.isEmpty && tags.moods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Genres & Moods', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),

        if (tags.genres.isNotEmpty) ...[
          Text(
            'GENRES',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              letterSpacing: 1.1,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '#$genre',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],

        if (tags.moods.isNotEmpty) ...[
          Text(
            'BOOK MOODS',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              letterSpacing: 1.1,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.moods.map((mood) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  mood,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showAuthorDetails(String authorName) {
    final theme = Theme.of(context);
    final AuthorService authorService = AuthorService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  Author? author;
                  List<Book> books = [];
                  try {
                    author = await authorService.fetchAuthorInfo(authorName);
                  } catch (e) {
                    print('Error loading author bio: $e');
                  }
                  try {
                    books = await widget.apiService.searchBooks(authorName);
                  } catch (e) {
                    print('Error loading author books: $e');
                  }
                  return {'author': author, 'books': books};
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return _buildAuthorErrorSheet(authorName);
                  }

                  final author = snapshot.data!['author'] as Author?;
                  final books = snapshot.data!['books'] as List<Book>;

                  if (author == null) {
                    return _buildAuthorErrorSheet(authorName);
                  }

                  return Stack(
                    children: [
                      ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        children: [
                          // Drag indicator bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Profile header row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author Avatar/Photo
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      author.photoUrl != null &&
                                          author.photoUrl!.isNotEmpty
                                      ? Image.network(
                                          author.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildFallbackAvatar(
                                                    author.name,
                                                  ),
                                        )
                                      : _buildFallbackAvatar(author.name),
                                ),
                              ),
                              const SizedBox(width: 20),

                              // Name & Lifespan Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author.name,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (author.birthDate != null ||
                                        author.deathDate != null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 14,
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${author.birthDate ?? "Unknown"} — ${author.deathDate ?? "Present"}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    if (author.wikipediaUrl != null) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Source: ${author.wikipediaUrl}',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Wikipedia Biography ↗',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Biography Text
                          Text(
                            'Biography',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            author.bio,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.85,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Horizontal scrollable Other Books Section
                          if (books.isNotEmpty) ...[
                            Text(
                              'Other Books by ${author.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final b = books[index];
                                  if (b.id == widget.bookId)
                                    return const SizedBox.shrink();

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context); // Close sheet
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BookDetailScreen(
                                                bookId: b.id,
                                                initialBook: b,
                                                firebaseService:
                                                    widget.firebaseService,
                                                apiService: widget.apiService,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: b.thumbnailUrl.isNotEmpty
                                                    ? Image.network(
                                                        b.thumbnailUrl,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              err,
                                                              stack,
                                                            ) =>
                                                                _buildFallbackCoverSmall(
                                                                  b.title,
                                                                ),
                                                      )
                                                    : _buildFallbackCoverSmall(
                                                        b.title,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            b.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
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
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((s) => s[0]).take(2).join('').toUpperCase()
        : 'A';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF1E6091)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFallbackCoverSmall(String title) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildAuthorErrorSheet(String authorName) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No details found for "$authorName"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We could not load biography info or dates for this author right now.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
