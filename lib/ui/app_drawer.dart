import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/app_colors.dart';
import '../pages/settings_page.dart';
import '../presentation/widgets/purchase_popup.dart';
import '../presentation/controllers/purchase_controller.dart';

/// A premium navigation drawer for the Color Mixer app.
/// Uses the centralized [AppColors] palette and subtle gradients.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseController = Get.find<PurchaseController>();
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Obx(() {
        final isPremium = purchaseController.adsRemoved.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Color Mixer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, color: AppColors.accent3, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'PRO MEMBER',
                            style: TextStyle(
                              color: AppColors.accent3,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: AppColors.accent3.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
            _buildTile(
              context,
              Icons.workspace_premium,
              isPremium ? 'Pro Settings' : 'Go Premium',
              () {
                Navigator.of(context).pop();
                showPurchasePopup();
              },
              iconColor: AppColors.accent3,
              textColor: isPremium ? AppColors.accent3 : Colors.white,
            ),
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
        );
      }),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.white),
      ),
      onTap: onTap,
    );
  }
}
