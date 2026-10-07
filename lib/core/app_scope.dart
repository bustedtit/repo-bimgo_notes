import 'package:flutter/widgets.dart';

import '../data/note_repository.dart';
import '../data/settings_store.dart';
import '../security/privacy_service.dart';

class Services {
  const Services({
    required this.repo,
    required this.privacy,
    required this.settings,
  });
  final NoteRepository repo;
  final PrivacyService privacy;
  final SettingsStore settings;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final Services services;

  static Services of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
