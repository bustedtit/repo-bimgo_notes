import 'package:flutter/material.dart';

import '../core/theme.dart';

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.background,
    this.foreground,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? background;
  final Color? foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? QN.panel(context),
          shape: BoxShape.circle,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) => ScaleTransition(
                    scale: a, child: FadeTransition(opacity: a, child: c)),
                child: Icon(icon,
                    key: ValueKey(icon),
                    size: size * 0.46,
                    color: onTap == null ? fg.withAlpha(90) : fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
