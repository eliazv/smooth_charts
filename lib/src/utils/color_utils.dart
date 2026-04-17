import 'package:flutter/material.dart';

Color lightenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(
    Colors.white.withValues(alpha: amount.clamp(0.0, 1.0)),
    color,
  );
}

Color darkenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(
    Colors.black.withValues(alpha: amount.clamp(0.0, 1.0)),
    color,
  );
}

Color dynamicPastel(
  BuildContext context,
  Color color, {
  double amount = 0.1,
  bool inverse = false,
  double? amountLight,
  double? amountDark,
}) {
  final light = (amountLight ?? amount).clamp(0.0, 1.0);
  final dark = (amountDark ?? amount).clamp(0.0, 1.0);
  final isLight = Theme.of(context).brightness == Brightness.light;
  if (inverse) {
    return isLight
        ? darkenPastel(color, amount: dark)
        : lightenPastel(color, amount: light);
  } else {
    return isLight
        ? lightenPastel(color, amount: light)
        : darkenPastel(color, amount: dark);
  }
}

class HexColor extends Color {
  static int _fromHex(String? hex, Color? fallback) {
    try {
      if (hex == null) return fallback?.toARGB32() ?? Colors.grey.toARGB32();
      hex = hex.replaceAll('#', '').replaceAll('0x', '');
      if (hex.length == 6) hex = 'FF$hex';
      return int.parse(hex, radix: 16);
    } catch (_) {
      return fallback?.toARGB32() ?? Colors.grey.toARGB32();
    }
  }

  HexColor(String? hexColor, {Color? defaultColor})
    : super(_fromHex(hexColor, defaultColor));
}
