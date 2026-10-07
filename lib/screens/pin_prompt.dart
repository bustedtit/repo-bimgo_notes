import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/routes.dart';
import '../widgets/pin_pad.dart';
import 'pin_setup_screen.dart';

/// True if private notes are unlocked afterwards (prompting for the PIN if needed).
Future<bool> ensureUnlocked(BuildContext context, {String? reason}) async {
  final s = AppScope.of(context);
  if (!s.privacy.hasPin) return false;
  if (s.privacy.isUnlocked) return true;
  return verifyPin(context,
      title: 'Enter your PIN', subtitle: reason ?? 'Unlock your private notes');
}

/// Always asks for the PIN (even when already unlocked) and verifies it.
Future<bool> verifyPin(BuildContext context,
    {required String title, String? subtitle, bool allowForgot = true}) async {
  final s = AppScope.of(context);
  final host = context;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: PinPad(
          title: title,
          subtitle: subtitle,
          onForgot: allowForgot
              ? () {
                  Navigator.pop(ctx, false);
                  if (host.mounted) confirmResetPrivate(host);
                }
              : null,
          onSubmit: (pin) async {
            final err = await s.privacy.unlock(pin);
            if (err == null) {
              HapticFeedback.selectionClick();
              if (ctx.mounted) Navigator.pop(ctx, true);
            }
            return err;
          },
        ),
      ),
    ),
  );
  if (ok == true) await s.repo.ensureDecrypted();
  return ok == true;
}

Future<bool> startPrivateSetup(BuildContext context) async {
  final ok = await Navigator.of(context)
      .push<bool>(softRoute(const PinSetupScreen(mode: SetupMode.create)));
  return ok == true;
}

Future<void> changePinFlow(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await verifyPin(context,
      title: 'Enter your current PIN',
      subtitle: 'We need your old PIN before you can change it.',
      allowForgot: false);
  if (!ok || !context.mounted) return;
  final done = await Navigator.of(context)
      .push<bool>(softRoute(const PinSetupScreen(mode: SetupMode.change)));
  if (done == true) {
    messenger.showSnackBar(const SnackBar(content: Text('PIN changed.')));
  }
}

Future<void> confirmResetPrivate(BuildContext context) async {
  final s = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Reset private notes?'),
      content: const Text(
          'This permanently deletes every private note and removes your PIN. '
          'It can\u2019t be undone. Only do this if you can\u2019t remember your PIN.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC9524B)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete & reset'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await s.repo.resetPrivateData();
    messenger.showSnackBar(const SnackBar(content: Text('Private notes reset.')));
  } catch (_) {
    messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\u2019t reset private notes.')));
  }
}
