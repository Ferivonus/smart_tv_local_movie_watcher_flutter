import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_tile.dart';
import '../widgets/tv_button.dart';

enum _LoadState { loading, error, loaded }

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final MovieService _movieService = MovieService();

  _LoadState _state = _LoadState.loading;
  List<Movie> _movies = [];
  String _errorMessage = '';

  final FocusNode _refreshFocusNode = FocusNode();
  List<FocusNode> _tileFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _refreshFocusNode.dispose();
    for (final node in _tileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _state = _LoadState.loading;
    });

    try {
      final movies = await _movieService.fetchMovies();
      if (!mounted) return;

      for (final node in _tileFocusNodes) {
        node.dispose();
      }
      _tileFocusNodes = List.generate(movies.length, (_) => FocusNode());

      setState(() {
        _movies = movies;
        if (movies.isEmpty) {
          _state = _LoadState.error;
          _errorMessage = 'Sunucuda oynatılabilir film bulunamadı.';
        } else {
          _state = _LoadState.loaded;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (movies.isNotEmpty) {
          _tileFocusNodes.first.requestFocus();
        } else {
          _refreshFocusNode.requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _LoadState.error;
        _errorMessage = e.toString();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshFocusNode.requestFocus();
      });
    }
  }

  void _openMovie(Movie movie) {
    context.pushNamed('player', extra: movie);
  }

  int _crossAxisCountFor(double width) {
    final count = (width / 240).floor();
    return count.clamp(2, 6);
  }

  KeyEventResult _handleTileNav(
    int index,
    int crossAxisCount,
    KeyEvent event,
  ) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      if ((index + 1) % crossAxisCount != 0 && index + 1 < _movies.length) {
        _tileFocusNodes[index + 1].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index % crossAxisCount != 0) {
        _tileFocusNodes[index - 1].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      final target = index + crossAxisCount;
      if (target < _movies.length) {
        _tileFocusNodes[target].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final target = index - crossAxisCount;
      if (target >= 0) {
        _tileFocusNodes[target].requestFocus();
      } else {
        _refreshFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'İzlenebilecek Filmler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TvButton(
                    focusNode: _refreshFocusNode,
                    icon: Icons.refresh_rounded,
                    size: 34,
                    onPressed: _loadMovies,
                    onNavigationKey: (event) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                          _movies.isNotEmpty) {
                        _tileFocusNodes.first.requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      case _LoadState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white54,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yukarıdaki yenile düğmesiyle tekrar deneyebilirsiniz.',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
            ],
          ),
        );
      case _LoadState.loaded:
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _crossAxisCountFor(constraints.maxWidth);
            return GridView.builder(
              itemCount: _movies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final movie = _movies[index];
                return MovieTile(
                  focusNode: _tileFocusNodes[index],
                  title: movie.title,
                  onPressed: () => _openMovie(movie),
                  onNavigationKey: (event) =>
                      _handleTileNav(index, crossAxisCount, event),
                );
              },
            );
          },
        );
    }
  }
}
