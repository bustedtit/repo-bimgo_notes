import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

class NoteColorPicker extends StatelessWidget {
  const NoteColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final int selected;
  final ValueChanged<Color> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: QN.noteColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = QN.noteColors[i];
          final isSel = c.value == selected;
          return Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(c);
              },
              child: Semantics(
                button: true,
                selected: isSel,
                label: 'Note color ${i + 1}',
                child: AnimatedScale(
                  scale: isSel ? 1.18 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? QN.ink.withAlpha(200) : QN.ink.withAlpha(35),
                        width: isSel ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A3E36).withAlpha(isSel ? 60 : 25),
                          blurRadius: isSel ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isSel ? 1 : 0,
                      child: const Icon(Icons.check_rounded, size: 18, color: QN.ink),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
