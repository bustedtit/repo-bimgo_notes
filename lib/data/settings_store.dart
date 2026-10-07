import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

class Draft {
  const Draft(this.title, this.content, this.colorValue);
  final String title;
  final String content;
  final int colorValue;
}

class SettingsStore extends ChangeNotifier {
  SharedPreferences? _p;
  ThemeMode _mode = ThemeMode.system;
  int _defaultColor = QN.cream.value;

  ThemeMode get themeMode => _mode;
  int get defaultColor => _defaultColor;

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _p = p;
      final i = (p.getInt('theme') ?? 0).clamp(0, 2).toInt();
      _mode = ThemeMode.values[i];
      _defaultColor = p.getInt('default_color') ?? _defaultColor;
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    try {
      await _p?.setInt('theme', m.index);
    } catch (_) {}
  }

  Future<void> setDefaultColor(int v) async {
    _defaultColor = v;
    notifyListeners();
    try {
      await _p?.setInt('default_color', v);
    } catch (_) {}
  }

  // Drafts are only ever stored for non-private notes.
  Draft? get draft {
    try {
      final raw = _p?.getString('draft');
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return Draft(m['t'] as String, m['c'] as String, m['k'] as int);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(String title, String content, int color) async {
    try {
      if (title.trim().isEmpty && content.trim().isEmpty) {
        await _p?.remove('draft');
      } else {
        await _p?.setString(
            'draft', jsonEncode({'t': title, 'c': content, 'k': color}));
      }
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    try {
      await _p?.remove('draft');
    } catch (_) {}
  }
}
