import 'package:anime_film_isle/models/movie.dart';
import 'package:anime_film_isle/services/movie_service.dart';
import 'package:anime_film_isle/widgets/movie_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/tv_button.dart';

enum _LoadState { loading, error, loaded }

class MediaListScreen extends StatefulWidget {
  const MediaListScreen({super.key});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  final MediaService _mediaService = MediaService();

  _LoadState _state = _LoadState.loading;
  List<MediaItem> _items = [];
  String _errorMessage = '';

  // İç içe klasörlerde gezinmek için mevcut yolları bir listede tutuyoruz
  final List<String> _pathHistory = [];

  final FocusNode _refreshFocusNode = FocusNode();
  List<FocusNode> _tileFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _refreshFocusNode.dispose();
    for (final node in _tileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentFolderPath =>
      _pathHistory.isEmpty ? '' : _pathHistory.last;

  Future<void> _loadMedia() async {
    setState(() {
      _state = _LoadState.loading;
    });

    try {
      final items = await _mediaService.fetchMedia(
        folderPath: _currentFolderPath,
      );
      if (!mounted) return;

      // Klasörün içindeysek en başa bir "Geri Dön" öğesi ekliyoruz
      if (_pathHistory.isNotEmpty) {
        items.insert(
          0,
          const MediaItem(title: 'Üst Klasöre Dön', isFolder: true, path: '..'),
        );
      }

      for (final node in _tileFocusNodes) {
        node.dispose();
      }
      _tileFocusNodes = List.generate(items.length, (_) => FocusNode());

      setState(() {
        _items = items;
        if (items.isEmpty) {
          _state = _LoadState.error;
          _errorMessage = 'Bu klasörde içerik bulunamadı.';
        } else {
          _state = _LoadState.loaded;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (items.isNotEmpty) {
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

  void _handleItemPress(MediaItem item) {
    if (item.path == "..") {
      // Geri Dön'e basıldı
      if (_pathHistory.isNotEmpty) {
        _pathHistory.removeLast();
        _loadMedia();
      }
    } else if (item.isFolder) {
      // Bir klasöre girildi
      _pathHistory.add(item.path);
      _loadMedia();
    } else {
      // Filme tıklandı, oynatıcıya gönder
      context.pushNamed('player', extra: item);
    }
  }

  int _crossAxisCountFor(double width) {
    final count = (width / 240).floor();
    return count.clamp(2, 6);
  }

  KeyEventResult _handleTileNav(int index, int crossAxisCount, KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      if ((index + 1) % crossAxisCount != 0 && index + 1 < _items.length) {
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
      if (target < _items.length) {
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
    // PopScope ile kumandadaki donanımsal Geri (Back) tuşunu dinliyoruz
    return PopScope(
      // Sadece ana dizindeysek (geçmiş boşsa) uygulamadan çıkışa izin ver
      canPop: _pathHistory.isEmpty,
      // DEĞİŞİKLİK BURADA: onPopInvoked yerine onPopInvokedWithResult kullanıldı
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Eğer didPop true ise sistem zaten geriye gitmiştir (ana dizindeyizdir)
        if (didPop) return;

        // Eğer didPop false ise (alt klasördeyiz demektir), üst klasöre dön
        if (_pathHistory.isNotEmpty) {
          _pathHistory.removeLast();
          _loadMedia();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(
          0xFF0F1115,
        ), // Daha koyu profesyonel arka plan
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentFolderPath.isEmpty
                            ? 'Medya Kütüphanesi'
                            : 'Klasör: ${_currentFolderPath.split('/').last}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    TvButton(
                      focusNode: _refreshFocusNode,
                      icon: Icons.refresh_rounded,
                      size: 34,
                      onPressed: _loadMedia,
                      onNavigationKey: (event) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                            _items.isNotEmpty) {
                          _tileFocusNodes.first.requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(child: _buildBody()),
              ],
            ),
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
        // BURASI DÜZELTİLDİ: Orijinal hata arayüzü geri getirildi
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
              itemCount: _items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 32,
                crossAxisSpacing: 32,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                return MediaTile(
                  focusNode: _tileFocusNodes[index],
                  item: item,
                  onPressed: () => _handleItemPress(item),
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
