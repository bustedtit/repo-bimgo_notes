import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/note.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.onPinTap,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onPinTap;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _expanded = false;

  static const _shapes = <BorderRadius>[
    BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(36)),
    BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(36),
        bottomLeft: Radius.circular(34),
        bottomRight: Radius.circular(24)),
    BorderRadius.all(Radius.circular(30)),
    BorderRadius.only(
        topLeft: Radius.circular(36),
        topRight: Radius.circular(28),
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(22)),
  ];

  static const _titleStyle = TextStyle(
      fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.25, color: QN.ink);

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final radius =
        _shapes[n.id.codeUnits.fold<int>(0, (a, b) => a + b) % _shapes.length];
    final len = n.content.length;
    final veryLong = !n.locked && len > 420;
    final maxLines = _expanded
        ? 80
        : len < 90
            ? 3
            : len < 260
                ? 6
                : len < 420
                    ? 9
                    : 12;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: ((v - 0.94) / 0.06).clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(scale: v, child: child),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF5A3E36).withAlpha(32),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Color(n.colorValue),
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: EdgeInsets.all(len < 90 ? 16 : 18),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (n.pinned || n.isPrivate) _badges(n),
                    if (n.locked)
                      _lockedBody()
                    else ...[
                      if (n.title.isNotEmpty)
                        Text(n.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle),
                      if (n.title.isNotEmpty && n.content.isNotEmpty)
                        const SizedBox(height: 6),
                      if (n.content.isNotEmpty)
                        Text(n.content,
                            maxLines: maxLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14.5,
                                height: 1.42,
                                color: QN.ink.withAlpha(215))),
                      if (veryLong) _moreToggle(),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      formatStamp(n.createdAt, withYear: true),
                      style: TextStyle(fontSize: 11.5, color: QN.ink.withAlpha(140)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badges(Note n) {
    Widget pin = Icon(Icons.push_pin_rounded, size: 16, color: QN.ink.withAlpha(200));
    if (widget.onPinTap != null) {
      pin = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPinTap,
        child: Padding(padding: const EdgeInsets.all(6), child: pin),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (n.isPrivate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: QN.ink.withAlpha(20), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: 12, color: QN.ink),
                SizedBox(width: 4),
                Text('Private',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QN.ink)),
              ]),
            ),
          if (n.isPrivate && n.pinned) const SizedBox(width: 6),
          if (n.pinned) pin,
        ],
      ),
    );
  }

  Widget _lockedBody() {
    Widget bar(double f) => FractionallySizedBox(
          widthFactor: f,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 9,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: QN.ink.withAlpha(28), borderRadius: BorderRadius.circular(6)),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: QN.ink.withAlpha(22), shape: BoxShape.circle),
          child: const Icon(Icons.lock_rounded, size: 20, color: QN.ink),
        ),
        const SizedBox(height: 10),
        const Text('Private note', style: _titleStyle),
        const SizedBox(height: 2),
        bar(.9),
        bar(.7),
        bar(.45),
      ],
    );
  }

  Widget _moreToggle() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_expanded ? 'Show less' : 'Show more',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: QN.ink.withAlpha(170))),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: Icon(Icons.expand_more_rounded, size: 18, color: QN.ink.withAlpha(170)),
            ),
          ]),
        ),
      );
}
