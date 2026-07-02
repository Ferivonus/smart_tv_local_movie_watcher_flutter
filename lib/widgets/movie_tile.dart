import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MovieTile extends StatefulWidget {
  final FocusNode focusNode;
  final String title;
  final VoidCallback onPressed;
  final KeyEventResult Function(KeyEvent event)? onNavigationKey;

  const MovieTile({
    super.key,
    required this.focusNode,
    required this.title,
    required this.onPressed,
    this.onNavigationKey,
  });

  @override
  State<MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<MovieTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
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
            duration: const Duration(milliseconds: 200),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.blueAccent.withValues(alpha: 0.85)
                : Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.white24,
              width: _isFocused ? 3 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    const BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_creation_rounded,
                size: 48,
                color: _isFocused ? Colors.white : Colors.white54,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _isFocused ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
