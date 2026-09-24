import 'dart:convert';

import 'package:colormixer/core/services/project_store.dart';
import 'package:colormixer/models/color_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ColorProject', () {
    test('JSON round-trip keeps counts, custom colors and notes', () {
      final p = ColorProject(
        id: '42',
        name: 'Wall',
        colorCounts: {'Red': 2, '#12AB34': 3},
        customColors: {'#12AB34': 0xFF12AB34},
        notes: 'living room',
      );

      final back = ColorProject.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );

      expect(back.id, '42');
      expect(back.name, 'Wall');
      expect(back.colorCounts, {'Red': 2, '#12AB34': 3});
      expect(back.customColors, {'#12AB34': 0xFF12AB34});
      expect(back.notes, 'living room');
      expect(back.mixedColor, p.mixedColor);
    });

    test('mix includes white, black and custom colors', () {
      expect(
        ColorProject.mix({'White': 1, 'Black': 1}, {}),
        const Color.fromARGB(255, 128, 128, 128),
      );
      expect(
        ColorProject.mix({'#00FF00': 2}, {'#00FF00': 0xFF00FF00}),
        const Color(0xFF00FF00),
      );
      expect(ColorProject.mix({}, {}), Colors.white);
    });

    test('labelOf names colors by hue, not nearest primary', () {
      expect(ColorProject.labelOf(const Color(0xFFDD6945)), 'Red-Orange');
      expect(ColorProject.labelOf(const Color(0xFFEF4444)), 'Red');
      expect(ColorProject.labelOf(const Color(0xFF22C55E)), 'Green');
      expect(ColorProject.labelOf(const Color(0xFF7A4A1A)), 'Brown');
      expect(ColorProject.labelOf(const Color(0xFFFFFFFF)), 'White');
      expect(ColorProject.labelOf(const Color(0xFF808080)), 'Gray');
    });
  });

  group('ProjectStore', () {
    test('first launch returns the sample project', () async {
      SharedPreferences.setMockInitialValues({});
      final list = await ProjectStore.load();
      expect(list.single.id, ColorProject.defaultProject.id);
    });

    test('saved projects load back newest first', () async {
      SharedPreferences.setMockInitialValues({});
      final older = ColorProject(
        id: 'a',
        name: 'Old',
        colorCounts: {'Blue': 1},
        updatedAt: DateTime(2025),
      );
      final newer = ColorProject(
        id: 'b',
        name: 'New',
        colorCounts: {'Red': 1},
        updatedAt: DateTime(2026),
      );
      await ProjectStore.save([older, newer]);

      final list = await ProjectStore.load();
      expect(list.map((p) => p.id), ['b', 'a']);
    });

    test('deleting every project stays empty (no sample re-added)', () async {
      SharedPreferences.setMockInitialValues({});
      await ProjectStore.save([]);
      expect(await ProjectStore.load(), isEmpty);
    });
  });
}
