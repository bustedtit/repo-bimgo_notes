import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_grid.dart';
import '../widgets/round_icon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      } else {
        _controller.clear();
        _focus.unfocus();
      }
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still up? 🌙';
    if (h < 12) return 'Good morning 🌷';
    if (h < 18) return 'Hi, lovely ☁️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final dark = QN.isDark(context);
    // Text colour that works on both the pastel and the plum backgrounds.
    final fg = Theme.of(context).colorScheme.onSurface;

    // No background here: QNBackdrop (in MaterialApp.builder) paints the gradient.
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: fg.withAlpha(150),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bingo',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: _searching
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  tooltip: _searching ? 'Close search' : 'Search',
                  background: QN.blush,
                  foreground: QN.ink,
                  onTap: _toggleSearch,
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.settings_rounded,
                  tooltip: 'Settings',
                  background: QN.lilac,
                  foreground: QN.ink,
                  onTap: widget.onOpenSettings,
                ),
              ],
            ),
          ),

          // ── Search field ─────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _searching
                ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: QN.glow(QN.rose, a: 45),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  cursorColor: QN.rose,
                  style: TextStyle(fontSize: 16, color: fg),
                  decoration: InputDecoration(
                    hintText: 'Search your notes… 🔍',
                    hintStyle: TextStyle(color: fg.withAlpha(110)),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: QN.rose,
                    ),
                    filled: true,
                    fillColor: dark
                        ? QN.darkSurface
                        : Colors.white.withAlpha(230),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide:
                      const BorderSide(color: QN.rose, width: 1.6),
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: 6),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([s.repo, _controller]),
              builder: (context, _) {
                if (!s.repo.loaded) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: QN.rose,
                    ),
                  );
                }

                final query = _controller.text.trim();
                // Pinned notes are not special on Home: newest first, like the rest.
                final notes = (query.isEmpty ? s.repo.all : s.repo.search(query))
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                final Widget child;

                if (s.repo.error != null && s.repo.all.isEmpty) {
                  child = EmptyState(
                    key: const ValueKey('error'),
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong.',
                    subtitle: s.repo.error!,
                  );
                } else if (s.repo.all.isEmpty) {
                  child = const EmptyState(
                    key: ValueKey('empty'),
                    icon: Icons.edit_note_rounded,
                    title: 'Nothing here yet.',
                    subtitle: 'Write down your first thought. 🌸',
                  );
                } else if (notes.isEmpty) {
                  child = EmptyState(
                    key: const ValueKey('none'),
                    icon: Icons.search_off_rounded,
                    title: 'No notes found.',
                    subtitle: s.repo.hasLockedPrivate
                        ? 'Locked private notes aren’t included in search.'
                        : 'Try a different word.',
                  );
                } else {
                  child = NoteGrid(
                    key: const ValueKey('grid'),
                    notes: notes,
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}