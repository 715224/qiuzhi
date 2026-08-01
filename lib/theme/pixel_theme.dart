import 'package:flutter/material.dart';

enum AppVisualTheme { cyanPixel, pinkMascot }

extension AppVisualThemeInfo on AppVisualTheme {
  String get storageValue => name;

  String get label => switch (this) {
        AppVisualTheme.cyanPixel => '青色像素',
        AppVisualTheme.pinkMascot => '粉色萌物',
      };
}

abstract final class PixelColors {
  static const cyan = Color(0xFF35C9C5);
  static const cyanDark = Color(0xFF087F7C);
  static const cyanDeep = Color(0xFF075B59);
  static const mint = Color(0xFFE7F9F7);
  static const mintSoft = Color(0xFFF3FCFB);
  static const paper = Color(0xFFF8FBFA);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF163230);
  static const muted = Color(0xFF6F8987);
  static const line = Color(0xFFBBD8D5);
  static const danger = Color(0xFFC64B4B);
}

@immutable
class PixelPalette extends ThemeExtension<PixelPalette> {
  final Color accent;
  final Color accentDark;
  final Color accentDeep;
  final Color soft;
  final Color softest;
  final Color paper;
  final Color white;
  final Color ink;
  final Color muted;
  final Color line;
  final Color danger;

  const PixelPalette({
    required this.accent,
    required this.accentDark,
    required this.accentDeep,
    required this.soft,
    required this.softest,
    required this.paper,
    required this.white,
    required this.ink,
    required this.muted,
    required this.line,
    required this.danger,
  });

  static const cyan = PixelPalette(
    accent: PixelColors.cyan,
    accentDark: PixelColors.cyanDark,
    accentDeep: PixelColors.cyanDeep,
    soft: PixelColors.mint,
    softest: PixelColors.mintSoft,
    paper: PixelColors.paper,
    white: PixelColors.white,
    ink: PixelColors.ink,
    muted: PixelColors.muted,
    line: PixelColors.line,
    danger: PixelColors.danger,
  );

  static const pink = PixelPalette(
    accent: Color(0xFFF2A7C5),
    accentDark: Color(0xFFB85E8B),
    accentDeep: Color(0xFF693652),
    soft: Color(0xFFFFE6F0),
    softest: Color(0xFFFFF5F9),
    paper: Color(0xFFFFFAFC),
    white: Color(0xFFFFFFFF),
    ink: Color(0xFF4A3040),
    muted: Color(0xFF8E7181),
    line: Color(0xFFE9BCD0),
    danger: Color(0xFFC64B65),
  );

  @override
  PixelPalette copyWith({
    Color? accent,
    Color? accentDark,
    Color? accentDeep,
    Color? soft,
    Color? softest,
    Color? paper,
    Color? white,
    Color? ink,
    Color? muted,
    Color? line,
    Color? danger,
  }) =>
      PixelPalette(
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
        accentDeep: accentDeep ?? this.accentDeep,
        soft: soft ?? this.soft,
        softest: softest ?? this.softest,
        paper: paper ?? this.paper,
        white: white ?? this.white,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        danger: danger ?? this.danger,
      );

  @override
  PixelPalette lerp(covariant PixelPalette? other, double t) {
    if (other == null) return this;
    return PixelPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      softest: Color.lerp(softest, other.softest, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      white: Color.lerp(white, other.white, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension PixelPaletteContext on BuildContext {
  PixelPalette get pixelPalette =>
      Theme.of(this).extension<PixelPalette>() ?? PixelPalette.cyan;
}

ThemeData buildPixelTheme({
  AppVisualTheme visualTheme = AppVisualTheme.cyanPixel,
}) {
  final palette = visualTheme == AppVisualTheme.pinkMascot
      ? PixelPalette.pink
      : PixelPalette.cyan;
  const radius = BorderRadius.all(Radius.circular(3));
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: palette.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: Brightness.light,
      primary: palette.accentDark,
      surface: palette.white,
      error: palette.danger,
    ),
  );

  final textTheme = base.textTheme.apply(
    fontFamily: 'monospace',
    bodyColor: palette.ink,
    displayColor: palette.ink,
  );

  return base.copyWith(
    extensions: [palette],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: palette.paper,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    ),
    dividerColor: palette.line,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: palette.accent,
        foregroundColor: palette.ink,
        disabledBackgroundColor: palette.line,
        disabledForegroundColor: palette.muted,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.ink, width: 2),
        ),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.ink, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accentDark,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.white,
      labelStyle: TextStyle(color: palette.accentDark),
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.ink, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.line, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.accentDark, width: 2),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.white,
      selectedColor: palette.accent,
      side: BorderSide(color: palette.ink, width: 1.5),
      shape: const RoundedRectangleBorder(borderRadius: radius),
      labelStyle: TextStyle(
        color: palette.ink,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
      ),
      showCheckmark: false,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.line,
      ),
      thumbColor: WidgetStatePropertyAll(palette.ink),
      trackOutlineColor: WidgetStatePropertyAll(palette.ink),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: TextStyle(color: palette.white),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: radius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.paper,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.ink, width: 2),
      ),
    ),
  );
}
