import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../core/config.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/color_picker.dart';
import 'pin_prompt.dart';
import 'privacy_info_screen.dart';

const _danger = Color(0xFFC9524B);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openInstagram(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(kDeveloperInstagramUrl),
          mode: LaunchMode.externalApplication);
      if (!ok) throw StateError('cannot launch');
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Couldn\u2019t open Instagram.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
        children: [
          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 2),
                Text('Make it yours 🎀',
                    style: TextStyle(fontSize: 14.5, color: QN.soft(context))),
              ],
            ),
          ),

          // ── Appearance ─────────────────────────────────
          _Section(
            title: 'Appearance',
            children: [
              ListenableBuilder(
                listenable: s.settings,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Default note color',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      NoteColorPicker(
                        selected: s.settings.defaultColor,
                        padding: EdgeInsets.zero,
                        onChanged: (c) {
                          HapticFeedback.selectionClick();
                          s.settings.setDefaultColor(c.toARGB32());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Privacy ────────────────────────────────────
          ListenableBuilder(
            listenable: s.privacy,
            builder: (context, _) {
              final p = s.privacy;
              return _Section(
                title: 'Privacy',
                children: [
                  _Tile(
                    icon: Icons.lock_rounded,
                    title: 'Private notes',
                    subtitle: !p.hasPin
                        ? 'Not set up yet'
                        : (p.isUnlocked ? 'Unlocked 🔓' : 'Locked 🔒'),
                    trailing: p.hasPin ? null : const _Pill('Set up'),
                    onTap: p.hasPin ? null : () => startPrivateSetup(context),
                  ),
                  _Tile(
                    icon: Icons.lock_clock_rounded,
                    title: 'Lock private notes now',
                    subtitle: 'They also lock when you leave the app',
                    onTap: p.hasPin && p.isUnlocked
                        ? () {
                      HapticFeedback.selectionClick();
                      p.lock();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Private notes locked. 🔒')));
                    }
                        : null,
                  ),
                  _Tile(
                    icon: Icons.password_rounded,
                    title: 'Change PIN',
                    subtitle: 'Requires your current PIN',
                    onTap: p.hasPin ? () => changePinFlow(context) : null,
                  ),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: 'Privacy information',
                    subtitle: 'What\u2019s stored and what isn\u2019t',
                    onTap: () => Navigator.of(context)
                        .push(softRoute<void>(const PrivacyInfoScreen())),
                  ),
                  _Tile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Reset private notes',
                    subtitle: 'Deletes all private notes and the PIN',
                    destructive: true,
                    onTap: p.hasPin ? () => confirmResetPrivate(context) : null,
                  ),
                ],
              );
            },
          ),

          // ── About ──────────────────────────────────────
          _Section(
            title: 'About',
            children: [
              const _Tile(
                icon: Icons.sell_outlined,
                title: 'Version',
                subtitle: kAppVersion,
                informational: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: QN.roseGlow,
                        shape: BoxShape.circle,
                        boxShadow: QN.glow(QN.rose, a: 80),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Thank you for using QuickNote.\nBuilt with care for the little thoughts that matter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 18),
                    Text('Follow the developer',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: QN.soft(context))),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: QN.rose,
                        foregroundColor: QN.ink,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _openInstagram(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Instagram \u2014 @bustedtit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = QN.isDark(context);

    // Hairline dividers between rows.
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 20,
          endIndent: 20,
          color: (dark ? QN.lilac : QN.blush).withAlpha(dark ? 30 : 120),
        ));
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: QN.soft(context),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: QN.panel(context),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: dark
                    ? QN.lilac.withAlpha(30)
                    : Colors.white.withAlpha(200),
                width: 1.5,
              ),
              boxShadow: dark
                  ? [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
                  : QN.glow(QN.rose, a: 28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      gradient: QN.roseGlow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: QN.ink,
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.informational = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final bool informational;

  @override
  Widget build(BuildContext context) {
    final dark = QN.isDark(context);
    final enabled = onTap != null;
    final active = enabled || trailing != null || informational;

    final base =
    destructive ? _danger : Theme.of(context).colorScheme.onSurface;
    final fg = active ? base : base.withAlpha(110);

    // Pastel circle behind each icon.
    final circle = destructive
        ? _danger.withAlpha(active ? 40 : 20)
        : (dark ? QN.lilac : QN.blush).withAlpha(active ? (dark ? 50 : 200) : 90);
    final iconColor = destructive ? fg : (dark ? QN.lilac : QN.ink);

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
        child: Icon(icon,
            size: 20, color: active ? iconColor : iconColor.withAlpha(110)),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: QN.soft(context))),
      trailing: trailing ??
          (enabled ? Icon(Icons.chevron_right_rounded, color: fg) : null),
    );
  }
}