import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/movie.dart';
import '../widgets/tv_button.dart';
import '../widgets/tv_thumbnail_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem movie;

  const VideoPlayerScreen({super.key, required this.movie});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;

  final FocusNode _rootFocusNode = FocusNode();
  final FocusNode _replayFocusNode = FocusNode();
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _forwardFocusNode = FocusNode();

  late final List<FocusNode> _controlFocusNodes;

  final int _thumbnailCount = 10;
  late List<FocusNode> _thumbnailNodes;

  int _lastFocusedThumbnailIndex = 0;

  @override
  void initState() {
    super.initState();

    _controlFocusNodes = [
      _replayFocusNode,
      _playPauseFocusNode,
      _forwardFocusNode,
    ];
    _thumbnailNodes = List.generate(_thumbnailCount, (index) => FocusNode());

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });
    //todo: kontrol et.
    final String? movieUrl = widget.movie.url;
    if (movieUrl == null || movieUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isInitialized = false;
      });
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(movieUrl));

    try {
      await _controller.initialize();
      if (!mounted) return;
      _controller.addListener(_onControllerUpdate);
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      await WakelockPlus.enable();
      _startHideTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playPauseFocusNode.requestFocus();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isInitialized = false;
      });
      await WakelockPlus.disable();
    }
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
      });
      WakelockPlus.disable();
    }
  }

  Future<void> _retryConnection() async {
    await _controller.dispose();
    await _initializePlayer();
  }

  void _showControlsPanel() {
    if (mounted && !_showControls) {
      setState(() {
        _showControls = true;
      });
      _playPauseFocusNode.requestFocus();
    }
    _startHideTimer();
  }

  void _hideControlsPanel() {
    if (mounted && _showControls) {
      setState(() {
        _showControls = false;
      });
      _rootFocusNode.requestFocus();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        _hideControlsPanel();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
    if (_controller.value.isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    _startHideTimer();
  }

  void _seekRelative(int seconds) {
    final currentPosition = _controller.value.position;
    final maxPosition = _controller.value.duration;
    var newPosition = currentPosition + Duration(seconds: seconds);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > maxPosition) newPosition = maxPosition;
    _controller.seekTo(newPosition);
    _startHideTimer();
  }

  void _seekToAbsolute(Duration position) {
    _controller.seekTo(position);
    _startHideTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "$hours:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  KeyEventResult _handleControlNav(int index, KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) _controlFocusNodes[index - 1].requestFocus();
      _startHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (index < _controlFocusNodes.length - 1) {
        _controlFocusNodes[index + 1].requestFocus();
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      final target = _lastFocusedThumbnailIndex.clamp(0, _thumbnailCount - 1);
      _thumbnailNodes[target].requestFocus();
      _startHideTimer();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleThumbnailNav(int index, KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) _thumbnailNodes[index - 1].requestFocus();
      _startHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (index < _thumbnailCount - 1) {
        _thumbnailNodes[index + 1].requestFocus();
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _playPauseFocusNode.requestFocus();
      _startHideTimer();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _rootFocusNode.dispose();
    _replayFocusNode.dispose();
    _playPauseFocusNode.dispose();
    _forwardFocusNode.dispose();
    for (var node in _thumbnailNodes) {
      node.dispose();
    }
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showControls,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showControls) {
          _hideControlsPanel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }
    if (!_isInitialized) {
      return _buildLoadingState();
    }
    return _buildPlayer();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.blueAccent),
        const SizedBox(height: 20),
        Text(
          "${widget.movie.title} yükleniyor...",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _retryConnection();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          Text(
            "${widget.movie.title} oynatılamadı",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Bağlantıyı kontrol edip tekrar deneyin.",
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TvButton(
            icon: Icons.refresh_rounded,
            size: 40,
            onPressed: _retryConnection,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.goBack) {
            if (_showControls) {
              _hideControlsPanel();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }

          if (!_showControls) {
            _showControlsPanel();
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.mediaPlayPause) {
              _togglePlayPause();
            }
            return KeyEventResult.handled;
          } else {
            _startHideTimer();
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, VideoPlayerValue value, child) {
              if (!value.isBuffering) return const SizedBox.shrink();
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            },
          ),
          GestureDetector(
            onTap: () =>
                _showControls ? _hideControlsPanel() : _showControlsPanel(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          if (_showControls)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                        Colors.black,
                      ],
                      stops: [0.4, 0.85, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TvButton(
                            focusNode: _replayFocusNode,
                            icon: Icons.replay_10,
                            size: 50,
                            onPressed: () => _seekRelative(-10),
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(0, event),
                          ),
                          const SizedBox(width: 40),
                          TvButton(
                            focusNode: _playPauseFocusNode,
                            icon: _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 70,
                            onPressed: _togglePlayPause,
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(1, event),
                          ),
                          const SizedBox(width: 40),
                          TvButton(
                            focusNode: _forwardFocusNode,
                            icon: Icons.forward_10,
                            size: 50,
                            onPressed: () => _seekRelative(10),
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(2, event),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 40,
                          right: 40,
                          top: 30,
                          bottom: 10,
                        ),
                        child: Row(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _controller,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                    return Text(
                                      _formatDuration(value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ExcludeFocus(
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.blueAccent,
                                    bufferedColor: Colors.white38,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 90,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: List.generate(_thumbnailCount, (index) {
                              final durationSeconds =
                                  _controller.value.duration.inSeconds > 0
                                  ? _controller.value.duration.inSeconds
                                  : 1;
                              final segmentSeconds =
                                  durationSeconds / _thumbnailCount;
                              final targetTime = Duration(
                                seconds: (segmentSeconds * index).round(),
                              );

                              return ValueListenableBuilder(
                                valueListenable: _controller,
                                builder:
                                    (context, VideoPlayerValue value, child) {
                                      final segmentStart = Duration(
                                        seconds: (segmentSeconds * index)
                                            .round(),
                                      );
                                      final segmentEnd = Duration(
                                        seconds: (segmentSeconds * (index + 1))
                                            .round(),
                                      );
                                      final isActive =
                                          value.position >= segmentStart &&
                                          value.position < segmentEnd;

                                      return TvThumbnailButton(
                                        focusNode: _thumbnailNodes[index],
                                        timeLabel: _formatDuration(targetTime),
                                        isActive: isActive,
                                        onFocus: () {
                                          _lastFocusedThumbnailIndex = index;
                                          _startHideTimer();
                                        },
                                        onPressed: () =>
                                            _seekToAbsolute(targetTime),
                                        onNavigationKey: (event) =>
                                            _handleThumbnailNav(index, event),
                                      );
                                    },
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
