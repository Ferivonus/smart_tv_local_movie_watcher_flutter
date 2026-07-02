class Movie {
  final String title;
  final String url;

  const Movie({required this.title, required this.url});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && other.title == title && other.url == url;

  @override
  int get hashCode => Object.hash(title, url);
}
