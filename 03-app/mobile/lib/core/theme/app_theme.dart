import 'package:flutter/material.dart';

import 'tokens.g.dart';

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.light ? RColors.light : RColors.dark;
  final text = TextTheme(
    displayLarge: RType.display,
    displayMedium: RType.display,
    displaySmall: RType.display,
    headlineLarge: RType.heading1,
    headlineMedium: RType.heading2,
    headlineSmall: RType.heading3,
    titleLarge: RType.heading4,
    titleMedium: RType.label,
    titleSmall: RType.label,
    bodyLarge: RType.bodyLg,
    bodyMedium: RType.body,
    bodySmall: RType.caption,
    labelLarge: RType.label,
    labelMedium: RType.label,
    labelSmall: RType.label,
  ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: 'ThmanyahSans',
    fontFamilyFallback: const ['IBMPlexSansArabic'],
    textTheme: text,
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accentDefault,
      onSecondary: c.accentOnAccent,
      error: c.actionDestructive,
      onError: c.textOnAction,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderStrong,
      outlineVariant: c.border,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surfaceSunken,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      shadow: c.surfaceOverlay,
      scrim: c.surfaceOverlay,
    ),
    scaffoldBackgroundColor: c.bg,
    dividerColor: c.border,
    disabledColor: c.textDisabled,
    extensions: [c],
  );
}
