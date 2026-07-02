import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MovieServiceException implements Exception {
  final String message;
  const MovieServiceException(this.message);

  @override
  String toString() => message;
}

class MovieService {
  static const String baseUrl = 'http://192.168.1.5:8080';

  static const String apiUrl = '$baseUrl/api/movies';

  Future<List<Movie>> fetchMovies() async {
    final Uri uri = Uri.parse(apiUrl);
    late final http.Response response;

    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const MovieServiceException(
        '$baseUrl adresine bağlanılamadı. Sunucunun açık ve aynı ağda '
        'olduğundan emin olun.',
      );
    }

    if (response.statusCode != 200) {
      throw MovieServiceException(
        'Sunucu $apiUrl adresinde ${response.statusCode} hatası döndürdü.',
      );
    }

    try {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final movies = <Movie>[];

      for (final item in jsonList) {
        final String title = item['title'];
        final String relativeUrl = item['url'];

        final String fullUrl = '$baseUrl$relativeUrl';

        movies.add(Movie(title: title, url: fullUrl));
      }

      movies.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      return movies;
    } catch (e) {
      throw MovieServiceException(
        'Film verileri okunurken bir hata oluştu: $e',
      );
    }
  }
}
