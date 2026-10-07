class Note {
  const Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.colorValue,
    this.title = '',
    this.content = '',
    this.pinned = false,
    this.isPrivate = false,
    this.cipher,
    this.locked = false,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final bool isPrivate;
  final int colorValue;

  /// Encrypted payload (base64) for private notes. Plain notes keep this null.
  final String? cipher;

  /// True for private notes whose text is not currently decrypted.
  final bool locked;

  Note copyWith({bool? pinned, int? colorValue}) => Note(
        id: id,
        title: title,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
        pinned: pinned ?? this.pinned,
        isPrivate: isPrivate,
        colorValue: colorValue ?? this.colorValue,
        cipher: cipher,
        locked: locked,
      );

  /// A copy with no plaintext (private notes only).
  Note asLocked() => !isPrivate
      ? this
      : Note(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          colorValue: colorValue,
          pinned: pinned,
          isPrivate: true,
          cipher: cipher,
          locked: true,
        );

  Note withPlain(String t, String c) => Note(
        id: id,
        title: t,
        content: c,
        createdAt: createdAt,
        updatedAt: updatedAt,
        colorValue: colorValue,
        pinned: pinned,
        isPrivate: true,
        cipher: cipher,
        locked: false,
      );

  /// [q] must already be lower-case. Locked private notes never match.
  bool matches(String q) {
    if (locked) return false;
    return title.toLowerCase().contains(q) || content.toLowerCase().contains(q);
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'title': isPrivate ? '' : title,
        'content': isPrivate ? (cipher ?? '') : content,
        'created': createdAt.millisecondsSinceEpoch,
        'updated': updatedAt.millisecondsSinceEpoch,
        'pinned': pinned ? 1 : 0,
        'is_private': isPrivate ? 1 : 0,
        'color': colorValue,
      };

  static Note? fromRow(Map<String, Object?> r) {
    try {
      final priv = (r['is_private'] as num?)?.toInt() == 1;
      final content = (r['content'] as String?) ?? '';
      return Note(
        id: r['id'] as String,
        title: priv ? '' : ((r['title'] as String?) ?? ''),
        content: priv ? '' : content,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((r['created'] as num).toInt()),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch((r['updated'] as num).toInt()),
        pinned: (r['pinned'] as num?)?.toInt() == 1,
        isPrivate: priv,
        colorValue: (r['color'] as num).toInt(),
        cipher: priv ? content : null,
        locked: priv,
      );
    } catch (_) {
      return null; // skip malformed rows instead of crashing
    }
  }
}
