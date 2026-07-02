import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final KeyEventResult Function(KeyEvent event)? onNavigationKey;
  final bool autofocus;

  const TvButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onPressed,
    this.focusNode,
    this.onFocus,
    this.onNavigationKey,
    this.autofocus = false,
  });

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
        if (hasFocus && widget.onFocus != null) {
          widget.onFocus!();
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isFocused
                ? Colors.blueAccent.withValues(alpha: 0.2)
                : Colors.transparent,
            boxShadow: _isFocused
                ? [
                    const BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
            border: _isFocused
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: _isFocused ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
