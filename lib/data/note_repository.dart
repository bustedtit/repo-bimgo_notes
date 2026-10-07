import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../security/privacy_service.dart';
import 'note_database.dart';

class NoteRepository extends ChangeNotifier {
  NoteRepository(this._db, this._privacy) {
    _privacy.addListener(_onPrivacy);
  }

  final NoteDatabase _db;
  final PrivacyService _privacy;

  List<Note> _notes = [];
  bool loaded = false;
  String? error;
  int _gen = 0;

  List<Note> get all => _notes;
  List<Note> get pinned => [for (final n in _notes) if (n.pinned) n];
  bool get hasLockedPrivate => _notes.any((n) => n.locked);
  Note? byId(String id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<Note> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _notes;
    return [for (final n in _notes) if (n.matches(q)) n];
  }

  Future<void> load() async {
    try {
      _notes = await _db.all();
      error = null;
      await _applyLock();
    } catch (_) {
      error = 'We couldn\u2019t open your notes.';
      _notes = [];
    }
    loaded = true;
    notifyListeners();
  }

  List<Note> _sort(List<Note> l) => l
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

  void _put(Note n) {
    final list = [..._notes];
    final i = list.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      list[i] = n;
    } else {
      list.add(n);
    }
    _notes = _sort(list);
  }

  Future<void> _applyLock() async {
    final gen = ++_gen;
    final next = <Note>[];
    for (final n in _notes) {
      if (!n.isPrivate) {
        next.add(n);
      } else if (!_privacy.isUnlocked || n.cipher == null) {
        next.add(n.asLocked());
      } else {
        try {
          final j = jsonDecode(await _privacy.decrypt(n.cipher!))
              as Map<String, dynamic>;
          next.add(n.withPlain(j['t'] as String, j['c'] as String));
        } catch (_) {
          next.add(n.asLocked());
        }
      }
    }
    if (gen != _gen) return; // superseded by a newer operation
    _notes = _sort(next);
  }

  void _onPrivacy() {
    if (!_privacy.isUnlocked) {
      _gen++;
      _notes = [for (final n in _notes) n.asLocked()];
      notifyListeners();
    } else {
      _applyLock().then((_) => notifyListeners());
    }
  }

  /// Call after a successful unlock to be sure plaintext is ready.
  Future<void> ensureDecrypted() async {
    if (_privacy.isUnlocked && _notes.any((n) => n.locked)) {
      await _applyLock();
      notifyListeners();
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';

  Future<Note> save({
    String? id,
    required String title,
    required String content,
    required int colorValue,
    required bool pinned,
    required bool isPrivate,
  }) async {
    final now = DateTime.now();
    final existing = id == null ? null : byId(id);
    String? cipher;
    if (isPrivate) {
      cipher = await _privacy.encrypt(jsonEncode({'t': title, 'c': content}));
    }
    final note = Note(
      id: id ?? _newId(),
      title: title,
      content: content,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      pinned: pinned,
      isPrivate: isPrivate,
      colorValue: colorValue,
      cipher: cipher,
    );
    await _db.upsert(note);
    _put(note);
    notifyListeners();
    return note;
  }

  Future<void> updateMeta(String id, {bool? pinned, int? color}) async {
    final n = byId(id);
    if (n == null) return;
    await _db.updateMeta(id, pinned: pinned, color: color);
    _put(n.copyWith(pinned: pinned, colorValue: color));
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final n = byId(id);
    if (n != null) await updateMeta(id, pinned: !n.pinned);
  }

  Future<void> delete(String id) async {
    await _db.delete(id);
    _notes = [for (final n in _notes) if (n.id != id) n];
    notifyListeners();
  }

  Future<void> restore(Note n) async {
    await _db.upsert(n);
    _put(n);
    if (n.isPrivate && _privacy.isUnlocked) await _applyLock();
    notifyListeners();
  }

  /// Re-encrypts every private note under [pending]'s key, then commits it.
  /// The old key must currently be unlocked (the caller verifies the old PIN).
  Future<void> changePin(PendingPin pending) async {
    final oldKey = _privacy.currentKey;
    if (oldKey == null) throw StateError('Private notes are locked.');
    final rows = await _db.privateRows();
    final updates = <String, String>{};
    for (final r in rows) {
      final plain =
          await PrivacyService.openWith(r['content'] as String, oldKey);
      updates[r['id'] as String] =
          await PrivacyService.sealWith(plain, pending.key);
    }
    await _db.rewriteContents(updates);
    await _privacy.commitPin(pending);
    await load();
  }

  Future<void> resetPrivateData() async {
    await _db.deletePrivate();
    await _privacy.wipe();
    await load();
  }
}
