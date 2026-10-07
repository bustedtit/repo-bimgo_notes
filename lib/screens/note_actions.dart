import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/note.dart';
import '../widgets/color_picker.dart';
import 'editor_screen.dart';
import 'pin_prompt.dart';

/// Destructive actions stay a soft brick-red so they read as "careful"
/// without clashing with the pink palette.
const _danger = Color(0xFFC9524B);

Future<void> openEditor(BuildContext context, {Note? note}) =>
    Navigator.of(context).push(softRoute<void>(EditorScreen(note: note)));

Future<void> openNote(BuildContext context, Note n) async {
  final s = AppScope.of(context);
  var note = n;
  if (n.locked) {
    final ok = await ensureUnlocked(context,
        reason: 'Unlock to open this private note');
    if (!ok || !context.mounted) return;
    note = s.repo.byId(n.id) ?? n;
    if (note.locked) return; // couldn't decrypt; never open an empty editor
  }
  if (!context.mounted) return;
  await openEditor(context, note: note);
}

Future<void> showNoteActions(BuildContext context, Note n) async {
  final s = AppScope.of(context);
  HapticFeedback.mediumImpact();
  // Background, shape and drag handle come from buildTheme()'s bottomSheetTheme.
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetLabel('Color'),
            NoteColorPicker(
              selected: n.colorValue,
              onChanged: (c) {
                HapticFeedback.selectionClick();
                s.repo.updateMeta(n.id, color: c.toARGB32());
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: n.pinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              iconBg: QN.blush,
              label: n.pinned ? 'Unpin' : 'Pin to Saved',
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                s.repo.togglePin(n.id);
              },
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              iconBg: _danger.withAlpha(45),
              iconColor: _danger,
              label: 'Delete',
              labelColor: _danger,
              onTap: () {
                Navigator.pop(ctx);
                confirmAndDelete(context, n);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: QN.soft(context),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.iconColor = QN.ink,
    this.labelColor,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = QN.isDark(context);
    return Material(
      color: dark ? Colors.white.withAlpha(16) : QN.blush.withAlpha(80),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: (labelColor ?? QN.soft(context))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deletes with an Undo snackbar. Private notes need the PIN and an explicit
/// confirmation first. Returns true if the note was deleted.
Future<bool> confirmAndDelete(BuildContext context, Note n) async {
  final s = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (n.isPrivate) {
    final ok = await ensureUnlocked(context,
        reason: 'Unlock to delete this private note');
    if (!ok || !context.mounted) return false;
    // Dialog shape/background/title style come from buildTheme()'s dialogTheme.
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete private note? 🔒'),
        content: Text(
          'This note is encrypted and can\u2019t be recovered once the Undo option disappears.',
          style: TextStyle(color: QN.soft(ctx)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true) return false;
  }
  final backup = n.asLocked(); // never keep plaintext of a private note around
  try {
    await s.repo.delete(n.id);
  } catch (_) {
    messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\u2019t delete that note.')));
    return false;
  }
  HapticFeedback.mediumImpact();
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: const Text('Note deleted 🗑️'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'Undo', onPressed: () => s.repo.restore(backup)),
    ));
  return true;
}