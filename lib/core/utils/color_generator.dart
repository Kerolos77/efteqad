import 'package:flutter/material.dart';

class ColorGenerator {
  // قائمة ألوان مميزة وثابتة ومريحة للعين
  static const List<Color> _palette = [
    Color(0xFF2563EB), // أزرق
    Color(0xFF059669), // أخضر زمردي
    Color(0xFFD97706), // عنبري / ذهبي
    Color(0xFFDC2626), // أحمر قرمزي
    Color(0xFF7C3AED), // بنفسجي
    Color(0xFF0891B2), // تركواز
    Color(0xFFEA580C), // برتقالي
    Color(0xFF4F46E5), // نيلي
    Color(0xFF0D9488), // زيتي مائي
    Color(0xFFBE185D), // وردي داكن
    Color(0xFF475569), // رمادي أردوازي
    Color(0xFF854D0E), // برونزي
  ];

  /// يُنتج لوناً ثابتاً وفريداً لكل خادم بناءً على معرفه أو إيميله
  static Color getColorForId(String? idOrEmail) {
    if (idOrEmail == null || idOrEmail.trim().isEmpty) {
      return Colors.grey.shade500;
    }

    int hash = 0;
    for (int i = 0; i < idOrEmail.length; i++) {
      hash = idOrEmail.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final index = hash.abs() % _palette.length;
    return _palette[index];
  }

  /// تحويل Color إلى Hex String
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// تحويل Hex String إلى Color
  static Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.blue;
    }
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}
