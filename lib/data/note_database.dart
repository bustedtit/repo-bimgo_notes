import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class NoteDatabase {
  Database? _db;
  static const _webKey = 'web_notes_v1';

  // ---------- Web fallback (browser storage) ----------
  Future<List<Map<String, Object?>>> _readWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return [for (final e in list) Map<String, Object?>.from(e as Map)];
  }

  Future<void> _writeWeb(List<Map<String, Object?>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webKey, jsonEncode(rows));
  }

  // ---------- Android (sqflite) ----------
  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'quicknote.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
CREATE TABLE notes(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created INTEGER NOT NULL,
  updated INTEGER NOT NULL,
  pinned INTEGER NOT NULL DEFAULT 0,
  is_private INTEGER NOT NULL DEFAULT 0,
  color INTEGER NOT NULL
)''');
        await db.execute('CREATE INDEX idx_notes_updated ON notes(updated DESC)');
      },
    );
    _db = db;
    return db;
  }

  Future<List<Note>> all() async {
    final List<Map<String, Object?>> rows;
    if (kIsWeb) {
      rows = await _readWeb();
      rows.sort((a, b) =>
          ((b['updated'] as num?) ?? 0).compareTo((a['updated'] as num?) ?? 0));
    } else {
      final db = await _open();
      rows = await db.query('notes', orderBy: 'updated DESC');
    }
    final out = <Note>[];
    for (final r in rows) {
      final n = Note.fromRow(r);
      if (n != null) out.add(n);
    }
    return out;
  }

  Future<void> upsert(Note n) async {
    if (kIsWeb) {
      final rows = await _readWeb();
      rows.removeWhere((r) => r['id'] == n.id);
      rows.add(n.toRow());
      await _writeWeb(rows);
      return;
    }
    final db = await _open();
    await db.insert('notes', n.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    if (kIsWeb) {
      final rows = await _readWeb();
      rows.removeWhere((r) => r['id'] == id);
      await _writeWeb(rows);
      return;
    }
    final db = await _open();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMeta(String id, {bool? pinned, int? color}) async {
    if (pinned == null && color == null) return;
    if (kIsWeb) {
      final rows = await _readWeb();
      for (final r in rows) {
        if (r['id'] == id) {
          if (pinned != null) r['pinned'] = pinned ? 1 : 0;
          if (color != null) r['color'] = color;
        }
      }
      await _writeWeb(rows);
      return;
    }
    final db = await _open();
    final values = <String, Object?>{
      if (pinned != null) 'pinned': pinned ? 1 : 0,
      if (color != null) 'color': color,
    };
    await db.update('notes', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> privateRows() async {
    if (kIsWeb) {
      final rows = await _readWeb();
      return [
        for (final r in rows)
          if ((r['is_private'] as num?)?.toInt() == 1)
            {'id': r['id'], 'content': r['content']}
      ];
    }
    final db = await _open();
    return db.query('notes',
        columns: ['id', 'content'], where: 'is_private = 1');
  }

  Future<void> rewriteContents(Map<String, String> byId) async {
    if (kIsWeb) {
      final rows = await _readWeb();
      for (final r in rows) {
        final v = byId[r['id']];
        if (v != null) r['content'] = v;
      }
      await _writeWeb(rows);
      return;
    }
    final db = await _open();
    await db.transaction((txn) async {
      for (final e in byId.entries) {
        await txn.update('notes', {'content': e.value},
            where: 'id = ?', whereArgs: [e.key]);
      }
    });
  }

  Future<void> deletePrivate() async {
    if (kIsWeb) {
      final rows = await _readWeb();
      rows.removeWhere((r) => (r['is_private'] as num?)?.toInt() == 1);
      await _writeWeb(rows);
      return;
    }
    final db = await _open();
    await db.delete('notes', where: 'is_private = 1');
  }
}