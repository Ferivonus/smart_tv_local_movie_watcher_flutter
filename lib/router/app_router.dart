import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_not_found_screen.dart';
import '../screens/video_player_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'movies',
      builder: (context, state) => const MediaListScreen(),
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! MediaItem) {
          return const MovieNotFoundScreen();
        }
        return VideoPlayerScreen(movie: extra);
      },
    ),
  ],
);
