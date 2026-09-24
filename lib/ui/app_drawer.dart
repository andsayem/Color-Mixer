import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/app_colors.dart';
import '../pages/settings_page.dart';
import '../presentation/widgets/purchase_popup.dart';
import '../presentation/controllers/purchase_controller.dart';

/// Navigation drawer for the Color Mixer app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseController = Get.find<PurchaseController>();
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Obx(() {
        final isPremium = purchaseController.adsRemoved.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(isPremium: isPremium),
            const SizedBox(height: 12),
            _DrawerTile(
              icon: Icons.home_rounded,
              title: 'Home',
              selected: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerTile(
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.of(context)
                  ..pop()
                  ..push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
              },
            ),
            const Spacer(),
            if (!isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ProCard(
                  onTap: () {
                    Navigator.of(context).pop();
                    showPurchasePopup();
                  },
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 20),
              child: Text(
                '© 2026 Polik Studios',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isPremium;
  const _Header({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 24,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(70)),
            ),
            child: const Icon(
              Icons.palette_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Color Mixer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.black87,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'PRO MEMBER',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Mix paints, discover colors',
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        selectedTileColor: AppColors.accent1.withAlpha(36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: selected ? AppColors.accent1 : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withAlpha(80)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.gold,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Go Pro',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Remove all ads',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
