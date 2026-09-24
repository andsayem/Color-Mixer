import 'package:flutter/material.dart';

class ColorProject {
  final String id;
  String name;
  Map<String, int> colorCounts;

  /// User-added colors: display name -> ARGB value.
  Map<String, int> customColors;
  DateTime updatedAt;
  String? notes;

  ColorProject({
    required this.id,
    required this.name,
    required this.colorCounts,
    Map<String, int>? customColors,
    DateTime? updatedAt,
    this.notes,
  }) : customColors = customColors ?? {},
       updatedAt = updatedAt ?? DateTime.now();

  /// The built-in paints every project starts with.
  static const Map<String, Color> primaries = {
    'Red': Color(0xFFEF4444),
    'Blue': Color(0xFF3B82F6),
    'Yellow': Color(0xFFF59E0B),
    'White': Color(0xFFFFFFFF),
    'Black': Color(0xFF000000),
  };

  int get totalDrops => colorCounts.values.fold(0, (s, v) => s + v);

  /// The paint color for [name], built-in or custom.
  Color? colorOf(String name) {
    final custom = customColors[name];
    return custom != null ? Color(custom) : primaries[name];
  }

  Color get mixedColor => mix(colorCounts, customColors);

  /// Averages every color by its number of drops.
  static Color mix(Map<String, int> counts, Map<String, int> customColors) {
    int rs = 0, gs = 0, bs = 0, total = 0;
    counts.forEach((name, cnt) {
      if (cnt <= 0) return;
      final custom = customColors[name];
      final c = custom != null ? Color(custom) : primaries[name];
      if (c == null) return;
      rs += _ch(c, 16) * cnt;
      gs += _ch(c, 8) * cnt;
      bs += _ch(c, 0) * cnt;
      total += cnt;
    });
    if (total == 0) return Colors.white;
    return Color.fromARGB(
      255,
      (rs / total).round(),
      (gs / total).round(),
      (bs / total).round(),
    );
  }

  static int _ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;

  static String hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';

  String get hexString => hexOf(mixedColor);

  String get colorLabel => labelOf(mixedColor);

  /// A human color name for [color], from its hue, saturation and
  /// lightness - e.g. "Red-Orange", "Dark Green", "Light Gray".
  static String labelOf(Color color) {
    final hsl = HSLColor.fromColor(color);
    final h = hsl.hue, s = hsl.saturation, l = hsl.lightness;

    // Near-neutral colors.
    if (l >= 0.95) return 'White';
    if (l <= 0.07) return 'Black';
    if (s < 0.12) {
      if (l >= 0.75) return 'Light Gray';
      if (l <= 0.3) return 'Dark Gray';
      return 'Gray';
    }

    // Dark, warm hues read as browns.
    if (h >= 10 && h < 50 && l < 0.4) return l < 0.22 ? 'Dark Brown' : 'Brown';

    final base = switch (h) {
      < 10 => 'Red',
      < 22 => 'Red-Orange',
      < 40 => 'Orange',
      < 50 => 'Amber',
      < 66 => 'Yellow',
      < 90 => 'Yellow-Green',
      < 150 => 'Green',
      < 175 => 'Teal',
      < 200 => 'Cyan',
      < 250 => 'Blue',
      < 275 => 'Indigo',
      < 300 => 'Purple',
      < 330 => 'Magenta',
      < 348 => 'Pink',
      _ => 'Red',
    };

    if (l >= 0.78) return 'Light $base';
    if (l <= 0.28) return 'Dark $base';
    if (s < 0.3) return 'Muted $base';
    return base;
  }

  ColorProject copyWith({
    String? name,
    Map<String, int>? colorCounts,
    Map<String, int>? customColors,
    String? notes,
  }) {
    return ColorProject(
      id: id,
      name: name ?? this.name,
      colorCounts: colorCounts ?? Map.from(this.colorCounts),
      customColors: customColors ?? Map.from(this.customColors),
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorCounts': colorCounts,
    'customColors': customColors,
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
  };

  factory ColorProject.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? v) => v is Map
        ? v.map((k, val) => MapEntry('$k', (val as num).toInt()))
        : <String, int>{};

    return ColorProject(
      id: '${json['id']}',
      name: '${json['name'] ?? 'Untitled Mix'}',
      colorCounts: intMap(json['colorCounts']),
      customColors: intMap(json['customColors']),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      notes: json['notes'] as String?,
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
