import 'dart:convert';
import 'dart:isolate';
import 'package:anime_film_isle/models/movie.dart';
import 'package:http/http.dart' as http;

class MediaServiceException implements Exception {
  final String message;
  const MediaServiceException(this.message);

  @override
  String toString() => message;
}

class MediaService {
  static const String baseUrl = 'http://192.168.1.5:8080';
  static const String apiUrl = '$baseUrl/api/movies';

  Future<List<MediaItem>> fetchMedia({String folderPath = ''}) async {
    final String urlString = folderPath.isEmpty
        ? apiUrl
        : '$apiUrl?path=${Uri.encodeQueryComponent(folderPath)}';

    final Uri uri = Uri.parse(urlString);
    late final http.Response response;

    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const MediaServiceException(
        'Sunucuya bağlanılamadı. Açık olduğundan emin olun.',
      );
    }

    if (response.statusCode != 200) {
      throw MediaServiceException(
        'Sunucu ${response.statusCode} hatası döndürdü.',
      );
    }

    try {
      // JSON parsing ve memory mapping işlemini ayrı bir Isolate'e (Actor) taşıyoruz.
      // Bu işlem UI thread'i bloklamadan arka planda çalışır ve tamamlandığında
      // List<MediaItem> referansını ana Isolate'e transfer eder.
      return await Isolate.run(() => _parseMediaItems(response.body));
    } catch (e) {
      throw MediaServiceException('Medya verileri okunurken hata oluştu: $e');
    }
  }

  /// Isolate içerisinde çalıştırılacak statik fonksiyon.
  /// Top-level veya static olmalıdır ki ana sınıftaki (this) referansları
  /// closure içerisine alıp gereksiz bellek kopyalamasına (serialization fail) yol açmasın.
  static List<MediaItem> _parseMediaItems(String responseBody) {
    final List<dynamic> jsonList = jsonDecode(responseBody);
    final items = <MediaItem>[];

    // Kapasite ön tahsisi (pre-allocation) yapılarak list grow overhead'i azaltılabilir,
    // ancak dynamic JSON dizilerinde length her zaman güvenilir olmayabilir.
    for (final item in jsonList) {
      final parsedItem = MediaItem.fromJson(item);

      items.add(
        MediaItem(
          title: parsedItem.title,
          url: parsedItem.url != null ? '$baseUrl${parsedItem.url}' : null,
          thumbnailUrl: parsedItem.thumbnailUrl != null
              ? '$baseUrl${parsedItem.thumbnailUrl}'
              : null,
          isFolder: parsedItem.isFolder,
          path: parsedItem.path,
        ),
      );
    }

    return items;
  }
}
