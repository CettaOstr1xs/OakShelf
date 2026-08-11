class Author {
  final String name;
  final String bio;
  final String? birthDate;
  final String? deathDate;
  final String? photoUrl;
  final String? wikipediaUrl;

  Author({
    required this.name,
    required this.bio,
    this.birthDate,
    this.deathDate,
    this.photoUrl,
    this.wikipediaUrl,
  });
}
