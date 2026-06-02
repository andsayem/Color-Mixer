import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../ui/app_colors.dart';

/// Settings page that lets the user customize accent colors using a color picker.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Color _selectedColor = AppColors.accent1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.bg,
      ),
      backgroundColor: AppColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Accent Color',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 12),
            // Color picker widget from flutter_colorpicker package
            BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Apply selected color to AppColors accent1 at runtime (demo purpose)
                // In a real app you would persist this setting and rebuild UI.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accent color updated (demo)')),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
