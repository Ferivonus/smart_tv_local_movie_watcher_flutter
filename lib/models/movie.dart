class MediaItem {
  final String title;
  final String? url;
  final String? thumbnailUrl;
  final bool isFolder;
  final String path;

  const MediaItem({
    required this.title,
    this.url,
    this.thumbnailUrl,
    required this.isFolder,
    required this.path,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] ?? '',
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      isFolder: json['is_folder'] ?? false,
      path: json['path'] ?? '',
    );
  }
}
