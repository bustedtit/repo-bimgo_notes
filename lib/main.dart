import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_scope.dart';
import 'data/note_database.dart';
import 'data/note_repository.dart';
import 'data/settings_store.dart';
import 'security/privacy_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final privacy = PrivacyService();
  final settings = SettingsStore();
  final repo = NoteRepository(NoteDatabase(), privacy);
  await Future.wait([privacy.init(), settings.init()]);
  runApp(QuickNoteApp(
    services: Services(repo: repo, privacy: privacy, settings: settings),
  ));
  // Notes load after the first frame so startup stays fast.
  unawaited(repo.load());
}