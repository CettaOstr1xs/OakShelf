import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote.dart';
import '../services/firebase_service.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';

class QuotesScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const QuotesScreen({super.key, required this.firebaseService});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _authorController = TextEditingController();
  final _bookController = TextEditingController();

  final _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _bookController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  void _openAddQuoteSheet() {
    final theme = Theme.of(context);
    _quoteController.clear();
    _authorController.clear();
    _bookController.clear();

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
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save a New Quote',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save wholesome lines or philosophical quotes that inspired you.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _quoteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'The Quote',
                      alignLabelWithHint: true,
                      hintText: '"Write the lines here..."',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Quote text is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      labelText: 'Author / Speaker',
                      hintText: 'e.g. Albert Camus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Author name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bookController,
                    decoration: InputDecoration(
                      labelText: 'Book Title (Optional)',
                      hintText: 'e.g. The Stranger',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final newQuote = Quote(
                            id: '',
                            quoteText: _quoteController.text.trim(),
                            author: _authorController.text.trim(),
                            bookTitle: _bookController.text.trim(),
                            dateAdded: DateTime.now(),
                          );
                          await widget.firebaseService.saveQuote(newQuote);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quote saved to your library!'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Quote',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyQuoteToClipboard(Quote quote) {
    final attribution = quote.bookTitle.isNotEmpty
        ? '— ${quote.author} in ${quote.bookTitle}'
        : '— ${quote.author}';
    final copyText = '"${quote.quoteText}" $attribution';
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quote copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteQuote(String quoteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote?'),
        content: const Text(
          'Are you sure you want to delete this saved quote?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.firebaseService.deleteQuote(quoteId);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Field Notes'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddQuoteSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Quote'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: NatureBackdrop(
        child: StreamBuilder<List<Quote>>(
          stream: widget.firebaseService.getQuotesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allQuotes = snapshot.data ?? [];

            return ValueListenableBuilder<String>(
              valueListenable: _searchQueryNotifier,
              builder: (context, searchQuery, _) {
                final filteredQuotes = allQuotes.where((q) {
                  if (searchQuery.trim().isEmpty) return true;
                  final query = searchQuery.toLowerCase();
                  final textMatch = q.quoteText.toLowerCase().contains(query);
                  final authorMatch = q.author.toLowerCase().contains(query);
                  final bookMatch = q.bookTitle.toLowerCase().contains(query);
                  return textMatch || authorMatch || bookMatch;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.oak.sand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: context.oak.onAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lines worth keeping',
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  '${allQuotes.length} saved reflections',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quotes Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search quotes by text, author, or book...',
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
                          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
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
                    ),

                    Expanded(
                      child: filteredQuotes.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    NatureEmptyState(
                                      icon: Icons.format_quote_rounded,
                                      title: searchQuery.isNotEmpty
                                          ? 'No matching field notes'
                                          : 'Your field notes are empty',
                                      message: searchQuery.isNotEmpty
                                          ? 'Try a different phrase, author, or book title.'
                                          : 'Save lines that stay with you while reading.',
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                110,
                              ),
                              itemCount: filteredQuotes.length,
                              itemBuilder: (context, index) {
                                final quote = filteredQuotes[index];
                                final hasBook = quote.bookTitle
                                    .trim()
                                    .isNotEmpty;
                                final attributionText = hasBook
                                    ? '— ${quote.author} in ${quote.bookTitle}'
                                    : '— ${quote.author}';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLowest
                                        .withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Left Accent Bar
                                          Container(
                                            width: 5,
                                            color: index.isEven
                                                ? Theme.of(context)
                                                    .colorScheme.primary
                                                : context.oak.ocean,
                                          ),

                                          // Main Card Content (Balanced & Centered)
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    14,
                                                    14,
                                                    16,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header Row: Quote Icon & Actions
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .format_quote_rounded,
                                                        color: theme
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.5),
                                                        size: 22,
                                                      ),
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            constraints:
                                                                const BoxConstraints(),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  4,
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .copy_rounded,
                                                              size: 17,
                                                            ),
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            tooltip:
                                                                'Copy Quote',
                                                            onPressed: () =>
                                                                _copyQuoteToClipboard(
                                                                  quote,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          IconButton(
                                                            constraints:
                                                                const BoxConstraints(),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  4,
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline_rounded,
                                                              size: 17,
                                                            ),
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            tooltip:
                                                                'Delete Quote',
                                                            onPressed: () =>
                                                                _confirmDeleteQuote(
                                                                  quote.id,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // Quote Text (Left-aligned)
                                                  Text(
                                                    '"${quote.quoteText}"',
                                                    textAlign: TextAlign.left,
                                                    style:
                                                        GoogleFonts.newsreader(
                                                          fontSize: 16.5,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.45,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 12),

                                                  // Bottom Attribution (Left-aligned: "— Author in Book Title")
                                                  Text(
                                                    attributionText,
                                                    textAlign: TextAlign.left,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontSize: 13,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(
                                  duration: 300.ms,
                                  delay: (index * 35).ms,
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
      ),
    );
  }
}
