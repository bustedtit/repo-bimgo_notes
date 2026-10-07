import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../widgets/pin_pad.dart';
import '../widgets/round_icon_button.dart';

enum SetupMode { create, change }

enum _Stage { intro, create, confirm }

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, this.mode = SetupMode.create});
  final SetupMode mode;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  late _Stage _stage =
      widget.mode == SetupMode.create ? _Stage.intro : _Stage.create;
  String _first = '';
  bool _ack = false;

  bool _isWeak(String p) {
    if (RegExp(r'^(\d)\1{3}$').hasMatch(p)) return true;
    return const {'1234', '4321', '0123', '3210', '2580'}.contains(p);
  }

  Future<String?> _onCreate(String pin) async {
    if (_isWeak(pin)) return 'That PIN is easy to guess. Try another.';
    setState(() {
      _first = pin;
      _stage = _Stage.confirm;
    });
    return null;
  }

  Future<String?> _onConfirm(String pin) async {
    if (pin != _first) return 'PINs don\u2019t match. Try again.';
    try {
      final s = AppScope.of(context);
      final pending = await s.privacy.preparePin(pin);
      if (widget.mode == SetupMode.change) {
        await s.repo.changePin(pending);
      } else {
        await s.privacy.commitPin(pending);
      }
      HapticFeedback.selectionClick();
      if (mounted) Navigator.of(context).pop(true);
      return null;
    } catch (_) {
      return 'Couldn\u2019t set the PIN. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _stage == _Stage.intro
                    ? _intro(context)
                    : Center(
                        key: ValueKey(_stage),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PinPad(
                                key: ValueKey('pad-$_stage'),
                                title: _stage == _Stage.create
                                    ? (widget.mode == SetupMode.change
                                        ? 'Choose a new PIN'
                                        : 'Choose your PIN')
                                    : 'Confirm your PIN',
                                subtitle: _stage == _Stage.create
                                    ? '4 digits you\u2019ll remember. Avoid obvious ones like 1234.'
                                    : 'Enter it once more to confirm.',
                                onSubmit:
                                    _stage == _Stage.create ? _onCreate : _onConfirm,
                              ),
                              if (_stage == _Stage.confirm)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _first = '';
                                    _stage = _Stage.create;
                                  }),
                                  child: const Text('Start over'),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final dark = QN.isDark(context);
    return SingleChildScrollView(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: QN.softPink, shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: QN.ink, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('Create your 4-digit PIN',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.1)),
          const SizedBox(height: 12),
          Text(
            'Your PIN locks and unlocks private notes. Private notes are encrypted on this device, '
            'hidden from previews and search while locked, and re-locked whenever you leave the app.',
            style: TextStyle(fontSize: 15.5, height: 1.45, color: QN.soft(context)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF3A2A28) : QN.softPeach.withAlpha(150),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('Please read', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Your private notes are protected by your PIN. If you forget your PIN, your private '
                  'notes cannot be recovered \u2014 not by you, and not by us. There is no reset that keeps '
                  'them. Keep your PIN somewhere safe.',
                  style: TextStyle(fontSize: 14.5, height: 1.45, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _ack = !_ack),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Checkbox(
                  value: _ack,
                  activeColor: QN.softPink,
                  checkColor: QN.ink,
                  onChanged: (v) => setState(() => _ack = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I understand that a forgotten PIN means my private notes are lost.',
                    style: TextStyle(fontSize: 14.5, height: 1.35),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: QN.softPink,
                foregroundColor: QN.ink,
                disabledBackgroundColor: QN.softPink.withAlpha(90),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: _ack ? () => setState(() => _stage = _Stage.create) : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
