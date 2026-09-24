import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/color_project.dart';

/// Saves the user's projects on the device so they survive app restarts.
class ProjectStore {
  static const _key = 'projects_v1';

  /// Loads saved projects, newest first. On the very first launch (nothing
  /// saved yet) returns a sample project so the home screen isn't empty.
  static Future<List<ColorProject>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [ColorProject.defaultProject];

      final list = (jsonDecode(raw) as List)
          .map((e) => ColorProject.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (e) {
      debugPrint('ProjectStore.load failed: $e');
      return [];
    }
  }

  static Future<void> save(List<ColorProject> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(projects.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ProjectStore.save failed: $e');
    }
  }
}
