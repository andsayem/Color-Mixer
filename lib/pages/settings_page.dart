import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../presentation/controllers/purchase_controller.dart';
import '../presentation/widgets/purchase_popup.dart';
import '../ui/app_colors.dart';

/// App settings: premium status, purchases, sharing and app info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.andsayem.colormixer';

  @override
  Widget build(BuildContext context) {
    final purchase = Get.find<PurchaseController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Obx(() => _PremiumCard(isPremium: purchase.adsRemoved.value)),
          const SizedBox(height: 28),
          const _SectionLabel('Purchases'),
          _SettingsGroup(
            children: [
              Obx(
                () => _SettingsTile(
                  icon: Icons.restore_rounded,
                  title: 'Restore purchases',
                  subtitle: 'Already bought Pro on another device?',
                  trailing: purchase.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent2,
                          ),
                        )
                      : null,
                  onTap: purchase.isLoading.value
                      ? null
                      : purchase.restorePurchase,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('App'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.ios_share_rounded,
                title: 'Share Color Mixer',
                subtitle: 'Send the app to a friend',
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: 'Check out the Color Mixer app! $_playStoreUrl',
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Color Mixer by Polik Studios',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Color Mixer',
                  applicationLegalese: '© 2026 Polik Studios',
                  applicationIcon: const Icon(
                    Icons.palette_rounded,
                    color: AppColors.accent1,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final bool isPremium;
  const _PremiumCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium ? AppColors.goldGradient : AppColors.accentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.gold : AppColors.accent1).withAlpha(
              70,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.auto_awesome_rounded,
              color: isPremium ? Colors.black87 : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'You are Pro' : 'Upgrade to Pro',
                  style: TextStyle(
                    color: isPremium ? Colors.black87 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'All ads are removed. Thank you!'
                      : 'Remove all ads for a cleaner experience.',
                  style: TextStyle(
                    color: isPremium ? Colors.black54 : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(width: 12),
            FilledButton(
              onPressed: showPurchasePopup,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent1,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Go Pro',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 64, color: AppColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent1.withAlpha(36),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent1, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
