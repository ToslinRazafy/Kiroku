import 'package:flutter/material.dart';

/// Identité visuelle "Encre de Manga" : contrastes forts, un rouge sceau
/// (hanko) comme unique accent, et des surfaces pensées comme des cases
/// de planche (bords nets, hairlines discrets) plutôt que du Material
/// générique.
class AppTheme {
  AppTheme._();

  // Accent unique : rouge sceau, utilisé avec parcimonie pour ponctuer
  // l'interface (statuts actifs, CTA, indicateur de progression...).
  static const _sealRedDark = Color(0xFFE1263F);
  static const _sealRedLight = Color(0xFFB8102A);

  // Nuit : encre presque noire, texte "papier".
  static const _inkBlack = Color(0xFF0B0B0D);
  static const _paperWhite = Color(0xFFF3F1EC);

  // Jour : planche imprimée, papier crème, encre noire.
  static const _paperCream = Color(0xFFF7F4EC);
  static const _inkText = Color(0xFF17161A);

  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? _sealRedDark : _sealRedLight;
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    final colorScheme = isDark
        ? base.copyWith(
            primary: _sealRedDark,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF3A1219),
            onPrimaryContainer: const Color(0xFFFFD9DD),
            surface: _inkBlack,
            onSurface: _paperWhite,
            surfaceContainerLowest: const Color(0xFF060607),
            surfaceContainerLow: const Color(0xFF101012),
            surfaceContainer: const Color(0xFF19191C),
            surfaceContainerHigh: const Color(0xFF212124),
            surfaceContainerHighest: const Color(0xFF2A2A2E),
            outline: const Color(0xFF45454A),
            outlineVariant: const Color(0xFF2A2A2E),
            shadow: Colors.black,
          )
        : base.copyWith(
            primary: _sealRedLight,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFFFDAD9),
            onPrimaryContainer: const Color(0xFF410006),
            surface: _paperCream,
            onSurface: _inkText,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: const Color(0xFFF4F0E6),
            surfaceContainer: const Color(0xFFEFEADD),
            surfaceContainerHigh: const Color(0xFFE7E1D2),
            surfaceContainerHighest: const Color(0xFFDFD8C6),
            outline: const Color(0xFFB7AF9C),
            outlineVariant: const Color(0xFFDAD3C1),
            shadow: Colors.black,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primary.withOpacity(0.16),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(
        color: scheme.onSurface.withOpacity(0.85),
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: scheme.onSurface.withOpacity(0.62),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
