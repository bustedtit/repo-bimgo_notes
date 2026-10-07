import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../widgets/round_icon_button.dart';

class PrivacyInfoScreen extends StatelessWidget {
  const PrivacyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold is transparent (see buildTheme), so QNBackdrop's gradient shows.
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: RoundIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                background: Colors.white.withAlpha(170),
                foreground: QN.ink,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Privacy 🔒',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: QN.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(
                'Your notes stay yours. 💗',
                style: TextStyle(fontSize: 14.5, color: QN.ink.withAlpha(150)),
              ),
            ),
            const SizedBox(height: 18),
            const _Block(
              icon: Icons.phone_android_rounded,
              tint: QN.blush,
              title: 'Stored on your device',
              body: 'Your notes, titles, colors and pins are saved in a database on this phone. '
                  'QuickNote works fully offline and has no account.',
            ),
            const _Block(
              icon: Icons.cloud_off_rounded,
              tint: QN.lilac,
              title: 'What QuickNote never does',
              body: 'It never sends your notes anywhere, never collects note content, and has no '
                  'analytics, ads or tracking. The app doesn\u2019t request internet access.',
            ),
            const _Block(
              icon: Icons.lock_rounded,
              tint: QN.blush,
              title: 'How private notes are protected',
              body: 'Private notes are encrypted with AES-256. The key comes from your PIN combined '
                  'with a secret kept in Android\u2019s secure storage on this device. Your PIN itself '
                  'is never saved. Private notes are hidden from previews and search while locked, '
                  'lock again when you leave the app, and the screen is protected from screenshots '
                  'while they\u2019re open.',
            ),
            const _Block(
              icon: Icons.warning_amber_rounded,
              tint: Color(0xFFFFE3D8), // soft peach: gentle "heads up"
              title: 'If you forget your PIN',
              body: 'Your private notes cannot be recovered. Resetting private notes in Settings '
                  'deletes them and removes the PIN.',
            ),
            const _Block(
              icon: Icons.info_outline_rounded,
              tint: QN.lilac,
              title: 'Good to know',
              body: 'A 4-digit PIN is convenient, not unbreakable: it has 10,000 possible values. '
                  'QuickNote slows down repeated wrong guesses, but someone with full access to an '
                  'unlocked or compromised phone could still be a risk. Because notes live only on '
                  'this device, uninstalling the app or losing the phone loses the notes.',
            ),
            if (kPrivacyPolicyUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: QN.glow(QN.rose, a: 80),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: QN.rose,
                      foregroundColor: QN.ink,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => launchUrl(Uri.parse(kPrivacyPolicyUrl),
                        mode: LaunchMode.externalApplication),
                    child: const Text('Read the full privacy policy'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QN.panel(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
        boxShadow: QN.glow(QN.rose, a: 28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 21, color: QN.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: QN.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: QN.ink.withAlpha(185),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}