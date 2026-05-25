import 'package:flutter/material.dart';
import '../ui/app_colors.dart';
import '../pages/settings_page.dart';

/// A premium navigation drawer for the Color Mixer app.
/// Uses the centralized [AppColors] palette and subtle gradients.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
            ),
            child: const Center(
              child: Text(
                'Color Mixer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildTile(context, Icons.home, 'Home', () {
            Navigator.of(context).pop();
          }),
          _buildTile(context, Icons.palette, 'Mix', () {
            // Placeholder for future navigation
            Navigator.of(context).pop();
          }),
          _buildTile(context, Icons.settings, 'Settings', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '© 2026 Polik Studios',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
