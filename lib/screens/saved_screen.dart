import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_grid.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    // No background here: QNBackdrop paints the gradient behind every screen.
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final notes = repo.pinned;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: QN.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notes.isEmpty
                                ? 'Pinned notes live here. 📌'
                                : 'Your favourites, kept close 💗',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: QN.ink.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Count badge
                    if (notes.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Container(
                          key: ValueKey(notes.length),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: QN.roseGlow,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: QN.glow(QN.rose, a: 70),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin_rounded,
                                  size: 15, color: QN.ink),
                              const SizedBox(width: 5),
                              Text(
                                '${notes.length}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: QN.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: !repo.loaded
                      ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: QN.rose,
                    ),
                  )
                      : notes.isEmpty
                      ? const EmptyState(
                    key: ValueKey('empty'),
                    icon: Icons.bookmark_border_rounded,
                    title: 'No saved notes yet.',
                    subtitle: 'Pin the notes you want to keep close. 🌸',
                  )
                      : NoteGrid(
                    key: const ValueKey('grid'),
                    notes: notes,
                    unpinOnPinTap: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}