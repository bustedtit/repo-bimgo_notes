import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// 4-digit PIN entry. [onSubmit] returns an error message, or null on success.
/// Give the widget a new Key to reset it between steps.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onSubmit,
    this.subtitle,
    this.onForgot,
  });

  final String title;
  final String? subtitle;
  final Future<String?> Function(String pin) onSubmit;
  final VoidCallback? onForgot;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  bool _busy = false;
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) {
      setState(() => _busy = true);
      final err = await widget.onSubmit(_pin);
      if (!mounted) return;
      if (err != null) {
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
        setState(() {
          _error = err;
          _pin = '';
          _busy = false;
        });
      } else {
        setState(() => _busy = false);
      }
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final dark = QN.isDark(context);
    final keyBg = dark ? QN.darkSurface : QN.peach.withAlpha(150);

    Widget key(String label) => _Key(
          bg: keyBg,
          onTap: () => _tap(label),
          child: Text(label,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: fg)),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, height: 1.35, color: QN.soft(context))),
          ),
        ],
        const SizedBox(height: 26),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value), 0),
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 4; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? fg : Colors.transparent,
                    border: Border.all(color: fg.withAlpha(150), width: 1.6),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey(_error),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              color: dark ? const Color(0xFFFF9C94) : const Color(0xFFB3261E))),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in row)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 9), child: key(d)),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: SizedBox(width: 72, height: 72)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 9), child: key('0')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _Key(
                bg: Colors.transparent,
                onTap: _back,
                child: Icon(Icons.backspace_outlined, color: fg, size: 24),
              ),
            ),
          ],
        ),
        if (widget.onForgot != null) ...[
          const SizedBox(height: 6),
          TextButton(onPressed: widget.onForgot, child: const Text('Forgot PIN?')),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.bg, required this.onTap, required this.child});
  final Color bg;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
