// import 'package:colormixer/common/admob_helper.dart';
import 'package:colormixer/common/admob_helper.dart';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob removed
import 'package:share_plus/share_plus.dart';
import '../models/color_project.dart';
import '../ui/app_colors.dart';
import '../ui/app_drawer.dart';
import '../ui/bg_painter.dart';
import 'mixer_page.dart' hide AppColors, BgPainter;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<ColorProject> _projects = [ColorProject.defaultProject];
  // BannerAd? _bannerAd; // Removed AdMob banner
  late AnimationController _rotateCtrl;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut));
    // AdMob interstitial and banner loading removed
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _openMixer(ColorProject project, {bool isNew = false}) async {
    final result = await Navigator.of(context).push<ColorProject>(
      MaterialPageRoute(
        builder: (_) => MixerPage(project: project, isNew: isNew),
      ),
    );
    if (result != null) {
      setState(() {
        final idx = _projects.indexWhere((p) => p.id == result.id);
        if (idx >= 0) {
          _projects[idx] = result;
        } else {
          _projects.insert(0, result);
        }
      });
    }
  }

  void _createNew() {
    _fabCtrl.forward().then((_) => _fabCtrl.reverse());
    _showCreateDialog();
  }

  Future<void> _showCreateDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NewProjectDialog(controller: ctrl),
    );
    if (result != null && result.trim().isNotEmpty) {
      AdmobHelper.showInterstitialAd();
      final proj = ColorProject.blank(name: result.trim());
      await _openMixer(proj, isNew: true);
    }
  }

  Future<void> _deleteProject(ColorProject project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: project.name),
    );
    if (ok == true) {
      setState(() => _projects.removeWhere((p) => p.id == project.id));
    }
  }

  void _shareApp() {
    Share.share('Check out the Color Mixer app! https://play.google.com/store/apps/details?id=com.andsayem.colormixer');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: const AppDrawer(),
      floatingActionButton: _buildFab(),
      body: Stack(
        children: [
          CustomPaint(
            painter: BgPainter(_rotateCtrl),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),

                // Banner ad removed
                if (_projects.isEmpty)
                  _buildEmptyState()
                else
                  _buildProjectList(),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      backgroundColor: AppColors.bg.withAlpha(200),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          tooltip: 'Share App',
          onPressed: _shareApp,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 50,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (r) =>
                        AppColors.accentGradient.createShader(r),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (r) =>
                        AppColors.accentGradient.createShader(r),
                    child: const Text(
                      'Color Mixer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'My paint mix projects',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final totalDrops = _projects.fold<int>(0, (s, p) => s + p.totalDrops);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.folder_rounded,
                label: 'Projects',
                value: '${_projects.length}',
                color: AppColors.accent1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.water_drop_rounded,
                label: 'Total Drops',
                value: '$totalDrops',
                color: AppColors.accent2,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.color_lens_rounded,
                label: 'Colors',
                value: _projects
                    .map((p) => p.colorLabel)
                    .toSet()
                    .length
                    .toString(),
                color: AppColors.accent3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Project List ──────────────────────────────────────────────────────────
  Widget _buildProjectList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final project = _projects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProjectCard(
              project: project,
              onEdit: () => {
                AdmobHelper.showInterstitialAd(),
                _openMixer(project),
              },
              onDelete: () => {
                AdmobHelper.showInterstitialAd(),
                _deleteProject(project),
              },
            ),
          );
        }, childCount: _projects.length),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No projects yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create your first paint mix',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return ScaleTransition(
      scale: _fabScale,
      child: GestureDetector(
        onTap: _createNew,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent1.withAlpha(100),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  final ColorProject project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final mixColor = p.mixedColor;
    final pct = p.totalDrops == 0
        ? {'Red': 0, 'Blue': 0, 'Yellow': 0}
        : {
            'Red': ((p.colorCounts['Red'] ?? 0) * 100 / p.totalDrops).round(),
            'Blue': ((p.colorCounts['Blue'] ?? 0) * 100 / p.totalDrops).round(),
            'Yellow': ((p.colorCounts['Yellow'] ?? 0) * 100 / p.totalDrops)
                .round(),
          };

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onEdit();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: mixColor.withAlpha(28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Color header strip ────────────────────────────────────
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: mixColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // shine
                    Positioned(
                      top: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withAlpha(40),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bars top-right
                    Positioned(
                      right: 14,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MiniBar(
                            'R',
                            pct['Red'] ?? 0,
                            const Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 4),
                          _MiniBar(
                            'B',
                            pct['Blue'] ?? 0,
                            const Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 4),
                          _MiniBar(
                            'Y',
                            pct['Yellow'] ?? 0,
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                    // Hex badge bottom-left
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.hexString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Card body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  p.colorLabel,
                                  style: const TextStyle(
                                    color: AppColors.accent2,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${p.totalDrops} drops',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (p.notes != null && p.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              p.notes!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Buttons ──────────────────────────────────────
                    Column(
                      children: [
                        _ActionBtn(
                          icon: Icons.edit_rounded,
                          gradient: AppColors.accentGradient,
                          onTap: widget.onEdit,
                          tooltip: 'Edit',
                        ),
                        const SizedBox(height: 8),
                        _ActionBtn(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFEF4444).withAlpha(20),
                          iconColor: const Color(0xFFEF4444),
                          onTap: widget.onDelete,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Bar ──────────────────────────────────────────────────────────────────
class _MiniBar extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;

  const _MiniBar(this.label, this.pct, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$pct%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final LinearGradient? gradient;
  final Color? color;
  final Color iconColor;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionBtn({
    required this.icon,
    this.gradient,
    this.color,
    this.iconColor = Colors.white,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Project Dialog ────────────────────────────────────────────────────────
class _NewProjectDialog extends StatelessWidget {
  final TextEditingController controller;
  const _NewProjectDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: const Icon(
                Icons.add_box_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'New Project',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Project name…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.label_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pop(controller.text.trim()),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete Dialog ─────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String name;
  const _DeleteDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Color(0xFFEF4444),
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Delete Project?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$name" will be permanently deleted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withAlpha(60),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
