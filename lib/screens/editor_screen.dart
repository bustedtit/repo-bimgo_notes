import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/note.dart';
import '../security/screen_security.dart';
import '../widgets/color_picker.dart';
import '../widgets/round_icon_button.dart';
import 'note_actions.dart';
import 'pin_prompt.dart';

enum _Leave { save, discard, stay }

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.note});
  final Note? note;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _color;
  late bool _pinned;
  late bool _private;
  late final Services _s;
  Timer? _draftTimer;
  bool _dirty = false;
  bool _saving = false;
  bool _veil = false;
  bool _draftRestored = false;

  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = AppScope.of(context);
    _s = s;
    final n = widget.note;
    _title = TextEditingController(text: n?.title ?? '');
    _body = TextEditingController(text: n?.content ?? '');
    // Respect the user's chosen default colour (Settings → Default note color).
    _color = n?.colorValue ?? s.settings.defaultColor;
    _pinned = n?.pinned ?? false;
    _private = n?.isPrivate ?? false;

    if (n == null) {
      final d = s.settings.draft;
      if (d != null) {
        _title.text = d.title;
        _body.text = d.content;
        _color = d.colorValue;
        _draftRestored = true;
      }
    }

    _title.addListener(_onChanged);
    _body.addListener(_onChanged);

    if (_private) ScreenSecurity.setSecure(true);

    if (_draftRestored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft restored ✨')),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _title.dispose();
    _body.dispose();
    ScreenSecurity.setSecure(_s.privacy.isUnlocked);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_private) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (mounted) setState(() => _veil = true);
    } else if (state == AppLifecycleState.resumed && _veil) {
      _resumePrivate();
    }
  }

  Future<void> _resumePrivate() async {
    final s = AppScope.of(context);
    if (s.privacy.isUnlocked) {
      setState(() => _veil = false);
      return;
    }
    final ok = await ensureUnlocked(context,
        reason: 'Unlock to continue editing');
    if (!mounted) return;
    if (ok) {
      setState(() => _veil = false);
    } else {
      _forcePop();
    }
  }

  void _forcePop() {
    setState(() {
      _saving = true;
      _dirty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _onChanged() {
    if (!_dirty) setState(() => _dirty = true);
    if (_isNew && !_private) {
      _draftTimer?.cancel();
      _draftTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        AppScope.of(context)
            .settings
            .saveDraft(_title.text, _body.text, _color);
      });
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _togglePin() async {
    HapticFeedback.lightImpact();
    setState(() => _pinned = !_pinned);
    _markDirty();
  }

  Future<void> _togglePrivate() async {
    HapticFeedback.selectionClick();
    if (_private) {
      setState(() => _private = false);
      ScreenSecurity.setSecure(AppScope.of(context).privacy.isUnlocked);
      _markDirty();
      return;
    }
    final s = AppScope.of(context);
    if (!s.privacy.hasPin) {
      final ok = await startPrivateSetup(context);
      if (!ok || !mounted) return;
    } else {
      final ok = await ensureUnlocked(context,
          reason: 'Unlock to make this note private');
      if (!ok || !mounted) return;
    }
    _draftTimer?.cancel();
    await s.settings.clearDraft();
    ScreenSecurity.setSecure(true);
    if (!mounted) return;
    setState(() => _private = true);
    _markDirty();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first! 💕')),
      );
      return;
    }
    final s = AppScope.of(context);
    if (_private && !s.privacy.isUnlocked) {
      final ok = await ensureUnlocked(context,
          reason: 'Unlock to save this private note');
      if (!ok || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await s.repo.save(
        id: widget.note?.id,
        title: title,
        content: body,
        colorValue: _color,
        pinned: _pinned,
        isPrivate: _private,
      );
      if (_isNew) await s.settings.clearDraft();
      HapticFeedback.selectionClick();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\u2019t save. Please try again.')),
      );
    }
  }

  // Dialog styling (shape, background, button colours) comes from buildTheme().
  Future<_Leave> _confirmLeave() async {
    final r = await showDialog<_Leave>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save this note? 🌸'),
        content: Text(
          _private
              ? 'You have unsaved changes to a private note.'
              : 'You have unsaved changes.',
          style: TextStyle(color: QN.soft(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _Leave.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _Leave.stay),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _Leave.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return r ?? _Leave.stay;
  }

  Future<void> _onBack() async {
    final r = await _confirmLeave();
    if (!mounted) return;
    switch (r) {
      case _Leave.save:
        await _save();
      case _Leave.discard:
        if (_isNew && !_private) {
          _draftTimer?.cancel();
          await AppScope.of(context).settings.clearDraft();
        }
        if (mounted) _forcePop();
      case _Leave.stay:
        break;
    }
  }

  Future<void> _delete() async {
    final n = widget.note;
    if (n == null) return;
    final deleted = await confirmAndDelete(context, n);
    if (deleted && mounted) _forcePop();
  }

  // ── Small pieces ─────────────────────────────────────────

  Widget _swap(Widget child) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    transitionBuilder: (c, a) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: c),
    ),
    child: child,
  );

  Widget _saveButton() {
    final enabled = !_saving;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          gradient: QN.roseGlow,
          borderRadius: BorderRadius.circular(26),
          boxShadow: enabled ? QN.glow(QN.rose, a: 100) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: enabled ? _save : null,
            child: const SizedBox(
              width: 92,
              height: 46,
              child: Center(
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: QN.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final bg = Color(_color);
    const ink = QN.ink;

    final chipBg = Colors.white.withAlpha(150);
    final chipBgActive = Colors.white.withAlpha(240);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: !_dirty || _saving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Stack(
              children: [
                // Dreamy wash: lighter at the top, a hint of lilac at the bottom.
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(bg, Colors.white, 0.45)!,
                          bg,
                          Color.lerp(bg, QN.lilac, 0.35)!,
                        ],
                      ),
                    ),
                  ),
                ),

                Column(
                  children: [
                    // ── Top bar ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            background: chipBg,
                            foreground: ink,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          if (n != null) ...[
                            RoundIconButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: 'Delete',
                              background: chipBg,
                              foreground: ink,
                              onTap: _delete,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _swap(RoundIconButton(
                            key: ValueKey('pin-$_pinned'),
                            icon: _pinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            tooltip: _pinned ? 'Unpin' : 'Pin',
                            background: _pinned ? chipBgActive : chipBg,
                            foreground: ink,
                            onTap: _togglePin,
                          )),
                          const SizedBox(width: 8),
                          _swap(RoundIconButton(
                            key: ValueKey('lock-$_private'),
                            icon: _private
                                ? Icons.lock_rounded
                                : Icons.lock_outline_rounded,
                            tooltip:
                            _private ? 'Make not private' : 'Make private',
                            background: _private ? chipBgActive : chipBg,
                            foreground: ink,
                            onTap: _togglePrivate,
                          )),
                          const SizedBox(width: 12),
                          _saveButton(),
                        ],
                      ),
                    ),

                    // ── Paper card: title + timestamp + body ──
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 18),
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(120),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withAlpha(190),
                              width: 1.5,
                            ),
                            boxShadow: QN.glow(ink, a: 28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              TextField(
                                controller: _title,
                                cursorColor: QN.rose,
                                textCapitalization:
                                TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: ink,
                                  height: 1.2,
                                ),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Title ✨',
                                  hintStyle: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: ink.withAlpha(70),
                                  ),
                                ),
                              ),

                              // Timestamp + private tag
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      n == null
                                          ? formatStamp(DateTime.now())
                                          : 'Edited ${formatStamp(n.updatedAt)}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: ink.withAlpha(130),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    if (_private) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: QN.lilac.withAlpha(200),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock_rounded,
                                                size: 11, color: ink),
                                            SizedBox(width: 4),
                                            Text(
                                              'Private',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Soft divider
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                child: Container(
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      QN.rose.withAlpha(90),
                                      QN.lilac.withAlpha(0),
                                    ]),
                                  ),
                                ),
                              ),

                              // Body
                              Expanded(
                                child: TextField(
                                  controller: _body,
                                  autofocus: _isNew,
                                  expands: true,
                                  maxLines: null,
                                  minLines: null,
                                  cursorColor: QN.rose,
                                  textAlignVertical: TextAlignVertical.top,
                                  textCapitalization:
                                  TextCapitalization.sentences,
                                  keyboardType: TextInputType.multiline,
                                  style: const TextStyle(
                                    fontSize: 17.5,
                                    height: 1.6,
                                    color: ink,
                                  ),
                                  decoration: InputDecoration.collapsed(
                                    hintText: 'Start writing your thoughts… 💭',
                                    hintStyle: TextStyle(
                                      fontSize: 17.5,
                                      height: 1.6,
                                      color: ink.withAlpha(85),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Color picker ─────────────────────────
                    NoteColorPicker(
                      selected: _color,
                      onChanged: (c) {
                        HapticFeedback.selectionClick();
                        setState(() => _color = c.toARGB32());
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),

                // ── Privacy veil ─────────────────────────────
                if (_veil)
                  Positioned.fill(
                    child: ColoredBox(
                      color: bg,
                      child: const Center(
                        child: Icon(Icons.lock_rounded, size: 44, color: ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}