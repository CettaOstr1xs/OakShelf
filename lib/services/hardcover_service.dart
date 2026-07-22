class HardcoverBookTags {
  final List<String> genres;
  final List<String> moods;

  HardcoverBookTags({
    required this.genres,
    required this.moods,
  });
}

class HardcoverService {
  /// Computes complete Hardcover genres and moods instantly with 0ms delay.
  static HardcoverBookTags getGenresAndMoodsSync({
    required String title,
    required List<String> authors,
    required List<String> categories,
    String description = '',
  }) {
    List<String> genres = [];
    List<String> moods = [];

    final fullText = '$title ${authors.join(' ')} $description ${categories.join(' ')}'.toLowerCase();

    // 1. HARDCOVER EXACT GENRES TAXONOMY
    if (categories.isNotEmpty) {
      for (var cat in categories) {
        final parts = cat.split('/');
        for (var p in parts) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'general') {
            genres.add(_mapCategoryToHardcoverGenre(trimmed));
          }
        }
      }
    }

    genres.addAll(_extractHardcoverGenres(fullText));

    // 2. HARDCOVER EXACT MOODS TAXONOMY (WITH EMOJIS)
    moods.addAll(_extractHardcoverMoods(fullText));

    return HardcoverBookTags(
      genres: genres.toSet().toList(),
      moods: moods.toSet().toList(),
    );
  }

  static String _mapCategoryToHardcoverGenre(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('fiction')) return 'Fiction';
    if (cat.contains('science fiction') || cat.contains('sci-fi')) return 'Science Fiction';
    if (cat.contains('fantasy')) return 'Fantasy';
    if (cat.contains('mystery') || cat.contains('detective') || cat.contains('thriller')) return 'Mystery & Thriller';
    if (cat.contains('romance')) return 'Romance';
    if (cat.contains('philosophy')) return 'Philosophy';
    if (cat.contains('history') || cat.contains('historical')) return 'Historical Fiction';
    if (cat.contains('biography') || cat.contains('autobiography') || cat.contains('memoir')) return 'Biography & Memoir';
    if (cat.contains('poetry')) return 'Poetry';
    if (cat.contains('psychology')) return 'Psychology';
    if (cat.contains('juvenile') || cat.contains('young adult')) return 'Young Adult';
    return category;
  }

  static List<String> _extractHardcoverGenres(String text) {
    List<String> genres = [];

    if (text.contains('campus') || text.contains('university') || text.contains('professor') || text.contains('academic')) {
      genres.add('Academic Fiction');
      genres.add('Literary Fiction');
      genres.add('Classics');
    }

    if (text.contains('fiction') || text.contains('novel') || text.contains('story')) {
      if (!genres.contains('Fiction')) genres.add('Fiction');
    }
    if (text.contains('classic') || text.contains('literature') || text.contains('masterpiece') || text.contains('19th century') || text.contains('20th century')) {
      genres.add('Classics');
      genres.add('Literary Fiction');
    }
    if (text.contains('sci-fi') || text.contains('science fiction') || text.contains('dystopian') || text.contains('space') || text.contains('future') || text.contains('cyberpunk')) {
      genres.add('Science Fiction');
    }
    if (text.contains('fantasy') || text.contains('magic') || text.contains('dragon') || text.contains('realm') || text.contains('sword')) {
      genres.add('Fantasy');
    }
    if (text.contains('crime') || text.contains('murder') || text.contains('mystery') || text.contains('detective') || text.contains('noir') || text.contains('thriller')) {
      genres.add('Mystery & Thriller');
    }
    if (text.contains('history') || text.contains('war') || text.contains('revolution') || text.contains('ancient') || text.contains('historical')) {
      genres.add('Historical Fiction');
    }
    if (text.contains('romance') || text.contains('love') || text.contains('relationship') || text.contains('marriage')) {
      genres.add('Romance');
    }
    if (text.contains('philosophy') || text.contains('existential') || text.contains('solitude') || text.contains('stoic') || text.contains('meaning')) {
      genres.add('Philosophy');
    }
    if (text.contains('memoir') || text.contains('biography') || text.contains('autobiography') || text.contains('life story')) {
      genres.add('Biography & Memoir');
    }
    if (text.contains('horror') || text.contains('spooky') || text.contains('haunted') || text.contains('ghost')) {
      genres.add('Horror');
    }

    if (genres.isEmpty) {
      genres.add('Literary Fiction');
    }

    return genres;
  }

  static List<String> _extractHardcoverMoods(String text) {
    List<String> moods = [];

    // Complete Hardcover Mood Tags
    if (text.contains('solitude') || text.contains('disappointment') || text.contains('estrange') || text.contains('quiet') || text.contains('sad') || text.contains('stoic') || text.contains('melancholy')) {
      moods.add('🕯️ Melancholy');
      moods.add('📜 Reflective');
      moods.add('🌾 Slow-paced');
      moods.add('🧠 Thought-provoking');
      moods.add('💖 Emotional');
    }

    if (text.contains('dark') || text.contains('death') || text.contains('murder') || text.contains('tragedy') || text.contains('grim') || text.contains('bleak')) {
      if (!moods.contains('🌙 Dark')) moods.add('🌙 Dark');
    }
    if (text.contains('thrilling') || text.contains('fast') || text.contains('action') || text.contains('chase') || text.contains('danger') || text.contains('race')) {
      moods.add('⚡ Fast-paced');
      moods.add('🎭 Tense');
    }
    if (text.contains('philosophy') || text.contains('mind') || text.contains('truth') || text.contains('existential') || text.contains('scholar') || text.contains('idea')) {
      if (!moods.contains('🧠 Thought-provoking')) moods.add('🧠 Thought-provoking');
    }
    if (text.contains('grief') || text.contains('love') || text.contains('heartbreak') || text.contains('moving') || text.contains('family') || text.contains('touching')) {
      if (!moods.contains('💖 Emotional')) moods.add('💖 Emotional');
    }
    if (text.contains('world') || text.contains('nature') || text.contains('setting') || text.contains('landscape') || text.contains('missouri') || text.contains('countryside')) {
      moods.add('🌿 Atmospheric');
    }
    if (text.contains('secret') || text.contains('hidden') || text.contains('mystery') || text.contains('curious') || text.contains('puzzle')) {
      moods.add('🔮 Mysterious');
    }
    if (text.contains('memory') || text.contains('past') || text.contains('old') || text.contains('years') || text.contains('childhood') || text.contains('forebears')) {
      if (!moods.contains('🕯️ Melancholy')) moods.add('🕯️ Melancholy');
    }
    if (text.contains('journey') || text.contains('explore') || text.contains('adventure') || text.contains('war') || text.contains('quest')) {
      moods.add('⚔️ Adventurous');
    }
    if (text.contains('hope') || text.contains('light') || text.contains('dream') || text.contains('inspire') || text.contains('triumph')) {
      moods.add('💫 Hopeful');
      moods.add('🎨 Inspiring');
    }
    if (text.contains('funny') || text.contains('humor') || text.contains('witty') || text.contains('charming') || text.contains('cozy')) {
      moods.add('✨ Lighthearted');
      moods.add('🛋️ Cozy');
    }

    if (moods.isEmpty) {
      moods = ['🧠 Thought-provoking', '🌿 Atmospheric', '📜 Reflective'];
    }

    return moods;
  }
}
