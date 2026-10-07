import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'editor_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _newNote() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  Widget _page() => switch (_index) {
    0 => HomeScreen(onOpenSettings: () => _go(2)),
    1 => const SavedScreen(),
    _ => const SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final dark = QN.isDark(context);

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: _page()),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: _index == 2,
        child: AnimatedScale(
          scale: _index == 2 ? 0 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: _PressableFab(onPressed: _newNote),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          // Shadow lives outside the clip so the blur doesn't cut it off.
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow:
              QN.glow(dark ? Colors.black : QN.rose, a: dark ? 90 : 55),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: dark
                        ? QN.darkSurface.withAlpha(210)
                        : Colors.white.withAlpha(175),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: dark
                          ? QN.lilac.withAlpha(45)
                          : Colors.white.withAlpha(220),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        label: 'Home',
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        selected: _index == 0,
                        onTap: () => _go(0),
                      ),
                      _NavItem(
                        label: 'Saved',
                        icon: Icons.bookmark_border_rounded,
                        selectedIcon: Icons.bookmark_rounded,
                        selected: _index == 1,
                        onTap: () => _go(1),
                      ),
                      _NavItem(
                        label: 'Settings',
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        selected: _index == 2,
                        onTap: () => _go(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = QN.isDark(context);
    // Selected pill is always pastel, so ink text is always readable on it.
    final fg = selected ? QN.ink : (dark ? QN.lilac : QN.ink.withAlpha(150));

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
              horizontal: selected ? 18 : 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [QN.blush, QN.lilac],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(26),
            boxShadow: selected ? QN.glow(QN.lilac, a: 90) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: Icon(selected ? selectedIcon : icon,
                    size: 22, color: fg),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableFab extends StatefulWidget {
  const _PressableFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_PressableFab> createState() => _PressableFabState();
}

class _PressableFabState extends State<_PressableFab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New note',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: QN.roseGlow,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(210), width: 2),
              boxShadow: QN.glow(QN.rose, a: 120),
            ),
            // The plus twists to a little "x" while pressed.
            child: AnimatedRotation(
              turns: _down ? 0.125 : 0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.add_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}