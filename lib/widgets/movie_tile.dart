import 'package:anime_film_isle/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MediaTile extends StatefulWidget {
  final FocusNode focusNode;
  final MediaItem item;
  final VoidCallback onPressed;
  final KeyEventResult Function(KeyEvent event)? onNavigationKey;

  const MediaTile({
    super.key,
    required this.focusNode,
    required this.item,
    required this.onPressed,
    this.onNavigationKey,
  });

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isBackButton = widget.item.path == "..";

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
        if (hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          if (widget.onNavigationKey != null) {
            final result = widget.onNavigationKey!(event);
            if (result == KeyEventResult.handled) return result;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: _isFocused
                  ? [
                      const BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackground(isBackButton),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.item.isFolder && !isBackButton)
                          const Icon(
                            Icons.folder_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: _isFocused
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isBackButton) {
    if (isBackButton) {
      return Container(
        color: Colors.white12,
        child: const Icon(Icons.reply_rounded, color: Colors.white54, size: 64),
      );
    }

    if (widget.item.isFolder) {
      return Container(
        color: Colors.blueAccent.withValues(alpha: 0.2),
        child: const Icon(
          Icons.folder_open_rounded,
          color: Colors.blueAccent,
          size: 72,
        ),
      );
    }

    if (widget.item.thumbnailUrl != null) {
      return Image.network(
        widget.item.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.white10,
      child: const Icon(
        Icons.movie_creation_rounded,
        color: Colors.white24,
        size: 64,
      ),
    );
  }
}
