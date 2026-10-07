import 'package:flutter/material.dart';

class QN {
  QN._();

  // ── Core palette ────────────────────────────────
  static const mist  = Color(0xFFFFF0F5);
  static const blush = Color(0xFFFCD6E6);
  static const lilac = Color(0xFFE4C1F9);
  static const rose  = Color(0xFFFF85A1);
  static const ink   = Color(0xFF4A1525); // deep berry, used for all text

  // ── Old names kept so existing screens keep working ──
  static const cream     = mist;
  static const peach     = lilac;
  static const softPeach = blush;
  static const softPink  = Color(0xFFFFB3C6); // buttons / chips

  // ── Dark mode: plum, not grey ───────────────────
  static const darkBg      = Color(0xFF1C1020);
  static const darkSurface = Color(0xFF2A1A30);

  static const noteColors = <Color>[
    mist,
    blush,
    lilac,
    Color(0xFFFFE3D8), // peach
    Color(0xFFFFF3C4), // butter
    Color(0xFFD8F3E4), // mint
    Color(0xFFD9E9FF), // sky
    Color(0xFFFFE6EE), // petal
  ];

  // ── Signature gradients and glow ─────────────────
  static const roseGlow = LinearGradient(
    colors: [Color(0xFFFF9EB5), Color(0xFFE4A7F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient background(bool dark) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: dark
        ? const [darkBg, Color(0xFF241328)]
        : const [Color(0xFFFFF5F9), Color(0xFFF6E9FC)],
  );

  static List<BoxShadow> glow(Color c, {int a = 90}) => [
    BoxShadow(
      color: c.withAlpha(a),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // ── Helpers ─────────────────────────────────────
  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Cards / settings sections: frosted white over the gradient.
  static Color panel(BuildContext c) =>
      isDark(c) ? darkSurface : Colors.white.withAlpha(185);

  static Color soft(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withAlpha(150);
}

/// Wrap the whole app once so every screen gets the gradient.
/// Use it in MaterialApp: builder: (context, child) => QNBackdrop(child: child!)
class QNBackdrop extends StatelessWidget {
  const QNBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: QN.background(QN.isDark(context))),
      child: child,
    );
  }
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final onSurface = dark ? const Color(0xFFF7E8F5) : QN.ink;
  final sheetBg = dark ? QN.darkSurface : const Color(0xFFFFF7FA);

  final scheme = ColorScheme.fromSeed(seedColor: QN.rose, brightness: b)
      .copyWith(
    primary: QN.rose,
    onPrimary: QN.ink, // berry on rose has better contrast than white
    secondary: QN.lilac,
    onSecondary: QN.ink,
    surface: sheetBg,
    onSurface: onSurface,
  );

  final base = ThemeData(brightness: b, useMaterial3: true);
  // For a journal feel: add google_fonts and use
  // GoogleFonts.quicksandTextTheme(base.textTheme) below instead.
  final text = base.textTheme.apply(bodyColor: onSurface, displayColor: onSurface);

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    textTheme: text,
    // Transparent so QNBackdrop's gradient shows through every Scaffold.
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: InkSparkle.splashFactory,

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? QN.lilac : QN.ink,
      contentTextStyle: TextStyle(
        color: dark ? QN.ink : QN.mist,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: dark ? QN.rose : QN.blush,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: sheetBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sheetBg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: QN.rose.withAlpha(120),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QN.rose,
        foregroundColor: QN.ink,
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: dark ? QN.lilac : QN.ink,
        shape: const StadiumBorder(),
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? QN.rose : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(color: QN.rose),

    listTileTheme: const ListTileThemeData(
      iconColor: QN.rose,
    ),
  );
}