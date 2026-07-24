import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/movie.dart';
import '../widgets/tv_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem movie;

  const VideoPlayerScreen({super.key, required this.movie});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _feedbackTimer;

  String _seekFeedback = "";
  bool _showSeekFeedback = false;
  bool _isScrubberFocused = false;

  final FocusNode _rootFocusNode = FocusNode();
  final FocusNode _replayFocusNode = FocusNode();
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _forwardFocusNode = FocusNode();
  final FocusNode _scrubberFocusNode = FocusNode();

  late final List<FocusNode> _controlFocusNodes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controlFocusNodes = [
      _replayFocusNode,
      _playPauseFocusNode,
      _forwardFocusNode,
      _scrubberFocusNode,
    ];

    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isInitialized && _controller.value.isPlaying) {
        _controller.pause();
        WakelockPlus.disable();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

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
      if (mounted && _controller.value.isPlaying && !_isScrubberFocused) {
        _hideControlsPanel();
      }
    });
  }

  void _triggerSeekFeedback(int seconds) {
    _feedbackTimer?.cancel();
    setState(() {
      _seekFeedback = seconds > 0 ? "+${seconds}s" : "${seconds}s";
      _showSeekFeedback = true;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showSeekFeedback = false;
        });
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
    _triggerSeekFeedback(seconds);
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
      if (index != 3) {
        _scrubberFocusNode.requestFocus();
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (index == 3) {
        _playPauseFocusNode.requestFocus();
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _rootFocusNode.dispose();
    _replayFocusNode.dispose();
    _playPauseFocusNode.dispose();
    _forwardFocusNode.dispose();
    _scrubberFocusNode.dispose();
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
        const CircularProgressIndicator(color: Colors.redAccent),
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
    final Size screenSize = MediaQuery.sizeOf(context);
    final double safeHorizontal = screenSize.width * 0.05;
    final double safeVertical = screenSize.height * 0.05;

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
                child: CircularProgressIndicator(color: Colors.redAccent),
              );
            },
          ),
          Center(
            child: AnimatedOpacity(
              opacity: _showSeekFeedback ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _seekFeedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                _showControls ? _hideControlsPanel() : _showControlsPanel(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 120,
                    bottom: safeVertical,
                    left: safeHorizontal,
                    right: safeHorizontal,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.7, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TvButton(
                            focusNode: _replayFocusNode,
                            icon: Icons.replay_10_rounded,
                            size: 36,
                            onPressed: () => _seekRelative(-10),
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(0, event),
                          ),
                          const SizedBox(width: 48),
                          TvButton(
                            focusNode: _playPauseFocusNode,
                            icon: _controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 48,
                            onPressed: _togglePlayPause,
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(1, event),
                          ),
                          const SizedBox(width: 48),
                          TvButton(
                            focusNode: _forwardFocusNode,
                            icon: Icons.forward_10_rounded,
                            size: 36,
                            onPressed: () => _seekRelative(10),
                            onFocus: _startHideTimer,
                            onNavigationKey: (event) =>
                                _handleControlNav(2, event),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              return Text(
                                _formatDuration(value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Focus(
                              focusNode: _scrubberFocusNode,
                              onFocusChange: (hasFocus) {
                                setState(() {
                                  _isScrubberFocused = hasFocus;
                                });
                                if (hasFocus) {
                                  _startHideTimer();
                                }
                              },
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft) {
                                    _seekRelative(-10);
                                    return KeyEventResult.handled;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                    _seekRelative(10);
                                    return KeyEventResult.handled;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowUp) {
                                    _playPauseFocusNode.requestFocus();
                                    _startHideTimer();
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: _isScrubberFocused ? 12 : 4,
                                decoration: BoxDecoration(
                                  boxShadow: _isScrubberFocused
                                      ? [
                                          const BoxShadow(
                                            color: Colors.redAccent,
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    padding: EdgeInsets.zero,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.redAccent,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatDuration(_controller.value.duration),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
