import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvThumbnailButton extends StatefulWidget {
  final FocusNode focusNode;
  final String timeLabel;
  final bool isActive;
  final VoidCallback onPressed;
  final VoidCallback onFocus;
  final KeyEventResult Function(KeyEvent event)? onNavigationKey;

  const TvThumbnailButton({
    super.key,
    required this.focusNode,
    required this.timeLabel,
    required this.onPressed,
    required this.onFocus,
    this.isActive = false,
    this.onNavigationKey,
  });

  @override
  State<TvThumbnailButton> createState() => _TvThumbnailButtonState();
}

class _TvThumbnailButtonState extends State<TvThumbnailButton> {
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
          widget.onFocus();
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
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          width: 140,
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.blueAccent.withValues(alpha: 0.9)
                : (widget.isActive ? Colors.white12 : Colors.white10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : (widget.isActive ? Colors.blueAccent : Colors.white24),
              width: _isFocused ? 3 : (widget.isActive ? 2 : 1),
            ),
            boxShadow: _isFocused
                ? [
                    const BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isActive
                    ? Icons.play_arrow_rounded
                    : Icons.smart_display_rounded,
                color: _isFocused
                    ? Colors.white
                    : (widget.isActive ? Colors.blueAccent : Colors.white54),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                widget.timeLabel,
                style: TextStyle(
                  color: _isFocused ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
