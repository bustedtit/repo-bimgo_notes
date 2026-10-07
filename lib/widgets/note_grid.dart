import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/note.dart';
import '../screens/note_actions.dart';
import '../core/app_scope.dart';
import 'note_card.dart';

class NoteGrid extends StatelessWidget {
  const NoteGrid({super.key, required this.notes, this.unpinOnPinTap = false});
  final List<Note> notes;
  final bool unpinOnPinTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 4 : width >= 600 ? 3 : 2;
    final repo = AppScope.of(context).repo;
    return MasonryGridView.count(
      crossAxisCount: cols,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final n = notes[i];
        return NoteCard(
          key: ValueKey(n.id),
          note: n,
          onTap: () => openNote(context, n),
          onLongPress: () => showNoteActions(context, n),
          onPinTap: unpinOnPinTap ? () => repo.togglePin(n.id) : null,
        );
      },
    );
  }
}
