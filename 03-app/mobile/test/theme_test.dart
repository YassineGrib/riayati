import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/theme/riayati_colors.dart';

void main() {
  test('themes follow semantic tokens and Arabic typography', () {
    final colors = jsonDecode(
      File('../../01-brand/tokens/colors.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    dynamic resolve(dynamic value) {
      if (value is String && value.startsWith('{')) {
        dynamic node = colors;
        for (final key in value.substring(1, value.length - 1).split('.')) {
          node = node[key];
        }
        return resolve(node[r'$value']);
      }
      return value;
    }

    final hex =
        resolve(colors['semantic']['action']['primary'][r'$value']) as String;
    final expected = Color(int.parse('ff${hex.substring(1)}', radix: 16));
    final light = buildTheme(Brightness.light);
    final dark = buildTheme(Brightness.dark);
    expect(light.extension<RColors>()!.primary, expected);
    expect(
      dark.extension<RColors>()!.bg,
      isNot(light.extension<RColors>()!.bg),
    );
    expect(light.textTheme.bodyMedium!.letterSpacing, 0);
    expect(light.textTheme.bodyMedium!.fontFamily, 'ThmanyahSans');
  });
}
