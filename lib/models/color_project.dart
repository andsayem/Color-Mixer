import 'package:flutter/material.dart';

class ColorProject {
  final String id;
  String name;
  Map<String, int> colorCounts;
  DateTime updatedAt;
  String? notes;

  ColorProject({
    required this.id,
    required this.name,
    required this.colorCounts,
    DateTime? updatedAt,
    this.notes,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get totalDrops => colorCounts.values.fold(0, (s, v) => s + v);

  Color get mixedColor {
    if (totalDrops == 0) return Colors.white;
    const redColor = Color(0xFFEF4444);
    const blueColor = Color(0xFF3B82F6);
    const yellowColor = Color(0xFFF59E0B);

    int rs = 0, gs = 0, bs = 0;
    void add(Color c, int cnt) {
      rs += _ch(c, 16) * cnt;
      gs += _ch(c, 8) * cnt;
      bs += _ch(c, 0) * cnt;
    }

    add(redColor, colorCounts['Red'] ?? 0);
    add(blueColor, colorCounts['Blue'] ?? 0);
    add(yellowColor, colorCounts['Yellow'] ?? 0);
    return Color.fromARGB(
      255,
      (rs / totalDrops).round(),
      (gs / totalDrops).round(),
      (bs / totalDrops).round(),
    );
  }

  int _ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;

  String get hexString {
    final c = mixedColor;
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  String get colorLabel {
    final color = mixedColor;
    int r = _ch(color, 16), g = _ch(color, 8), b = _ch(color, 0);
    final refs = {
      'Red': [239, 68, 68],
      'Blue': [59, 130, 246],
      'Yellow': [245, 158, 11],
      'Orange': [249, 115, 22],
      'Green': [34, 197, 94],
      'Purple': [168, 85, 247],
      'Pink': [236, 72, 153],
      'Brown': [120, 53, 15],
      'Gray': [148, 163, 184],
      'White': [255, 255, 255],
    };
    String nearest = 'Custom';
    int best = 9999;
    refs.forEach((name, rgb) {
      final d = (r - rgb[0]).abs() + (g - rgb[1]).abs() + (b - rgb[2]).abs();
      if (d < best) {
        best = d;
        nearest = name;
      }
    });
    return nearest;
  }

  ColorProject copyWith({
    String? name,
    Map<String, int>? colorCounts,
    String? notes,
  }) {
    return ColorProject(
      id: id,
      name: name ?? this.name,
      colorCounts: colorCounts ?? Map.from(this.colorCounts),
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }

  static ColorProject blank({String name = 'New Mix'}) => ColorProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        colorCounts: {'Red': 0, 'Blue': 0, 'Yellow': 0},
      );

  static ColorProject get defaultProject => ColorProject(
        id: 'default_001',
        name: 'Sunset Orange',
        colorCounts: {'Red': 5, 'Blue': 1, 'Yellow': 3},
        notes: 'Warm sunset tones for wall art.',
      );
}
