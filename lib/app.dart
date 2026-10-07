import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'security/screen_security.dart';

class QuickNoteApp extends StatefulWidget {
  const QuickNoteApp({super.key, required this.services});
  final Services services;

  @override
  State<QuickNoteApp> createState() => _QuickNoteAppState();
}

class _QuickNoteAppState extends State<QuickNoteApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.services.privacy.addListener(_syncSecure);
  }

  @override
  void dispose() {
    widget.services.privacy.removeListener(_syncSecure);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Screenshots / recents preview are blocked while private notes are unlocked.
  void _syncSecure() =>
      ScreenSecurity.setSecure(widget.services.privacy.isUnlocked);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.services.privacy.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: ListenableBuilder(
        listenable: widget.services.settings,
        builder: (context, _) => MaterialApp(
          title: 'QuickNote',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          themeMode: ThemeMode.light, // always light
          home: const HomeShell(),
        ),
      ),
    );
  }
}