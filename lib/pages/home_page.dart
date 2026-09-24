import 'package:admob_kit/admob_kit.dart';
import 'package:colormixer/widget/adaptive_banner_ad.dart';
import 'package:colormixer/presentation/widgets/purchase_popup.dart';
import 'package:get/get.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/services/project_store.dart';
import '../models/color_project.dart';
import '../ui/app_colors.dart';
import '../ui/app_drawer.dart';
import '../ui/bg_painter.dart';
import 'mixer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<ColorProject> _projects = [];
  bool _loaded = false;
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
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final saved = await ProjectStore.load();
    if (!mounted) return;
    setState(() {
      _projects
        ..clear()
        ..addAll(saved);
      _loaded = true;
    });
  }

  void _persist() => ProjectStore.save(_projects);

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
      // Most recently edited project goes to the top.
      setState(() {
        _projects
          ..removeWhere((p) => p.id == result.id)
          ..insert(0, result);
      });
      _persist();
    }
  }

  void _createNew() {
    _fabCtrl.forward().then((_) => _fabCtrl.reverse());
    _showCreateDialog();
  }

  Future<void> _showCreateDialog() async {
    // Load now so the interstitial shown after this dialog is ready.
    InterstitialAdManager.load();
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NewProjectDialog(controller: ctrl),
    );
    if (result != null) {
      AdManager.showInterstitial();
      final proj = ColorProject.blank(
        name: result.trim().isEmpty ? 'New Mix' : result.trim(),
      );
      await _openMixer(proj, isNew: true);
    }
  }

  Future<void> _deleteProject(ColorProject project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: project.name),
    );
    if (ok != true || !mounted) return;

    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index < 0) return;
    setState(() => _projects.removeAt(index));
    _persist();
    AdManager.registerAction();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${project.name}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.accent2,
            onPressed: () {
              if (!mounted) return;
              setState(
                () =>
                    _projects.insert(index.clamp(0, _projects.length), project),
              );
              _persist();
            },
          ),
        ),
      );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out the Color Mixer app! https://play.google.com/store/apps/details?id=com.andsayem.colormixer',
      ),
    );
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
                if (!_loaded)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (_projects.isEmpty)
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
        Obx(() {
          final isPremium = Get.find<PurchaseController>().adsRemoved.value;
          return _PremiumBadge(isPremium: isPremium, onTap: showPurchasePopup);
        }),
        IconButton(
          icon: const Icon(
            Icons.ios_share_rounded,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Share App',
          onPressed: _shareApp,
        ),
        const SizedBox(width: 4),
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
              const SizedBox(height: 4),
              Text(
                _projects.isEmpty
                    ? 'Start your first paint mix'
                    : '${_projects.length} paint mix '
                          '${_projects.length == 1 ? 'project' : 'projects'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Project List ──────────────────────────────────────────────────────────
  /// In-feed ad after the 2nd project, then after every 5 more. The list is
  /// built lazily, so each ad is only requested when scrolled near.
  static bool _adAfter(int projectIndex) =>
      projectIndex >= 1 && (projectIndex - 1) % 5 == 0;

  Widget _buildProjectList() {
    final items = <Widget>[];
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      items.add(
        Padding(
          key: ValueKey(project.id),
          padding: const EdgeInsets.only(bottom: 14),
          child: _ProjectCard(
            project: project,
            onEdit: () {
              AdManager.registerAction();
              _openMixer(project);
            },
            onDelete: () => _deleteProject(project),
          ),
        ),
      );
      if (_adAfter(i)) {
        items.add(
          InlineAdCard(
            key: ValueKey('ad_$i'),
            margin: const EdgeInsets.only(bottom: 14),
          ),
        );
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
          findChildIndexCallback: (key) {
            final i = items.indexWhere((w) => w.key == key);
            return i < 0 ? null : i;
          },
        ),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent1.withAlpha(90),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.palette_outlined,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
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
              'Mix red, blue and yellow drops\nto discover new colors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _createNew,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, color: AppColors.accent2),
              label: const Text(
                'Create a project',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent1.withAlpha(100),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'New Mix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium Badge ─────────────────────────────────────────────────────────────
class _PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onTap;

  const _PremiumBadge({required this.isPremium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isPremium ? AppColors.goldGradient : null,
              color: isPremium ? null : AppColors.gold.withAlpha(24),
              borderRadius: BorderRadius.circular(20),
              border: isPremium
                  ? null
                  : Border.all(color: AppColors.gold.withAlpha(90)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: isPremium ? Colors.black87 : AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  isPremium ? 'PRO' : 'Go Pro',
                  style: TextStyle(
                    color: isPremium ? Colors.black87 : AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
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
    // The paints in this mix, for the recipe strip.
    final recipe = p.colorCounts.entries
        .where((e) => e.value > 0 && p.colorOf(e.key) != null)
        .toList();

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
                    // Recipe strip: each paint's share of the mix.
                    if (recipe.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 6,
                        child: Row(
                          children: [
                            for (final e in recipe)
                              Expanded(
                                flex: e.value,
                                child: ColoredBox(color: p.colorOf(e.key)!),
                              ),
                          ],
                        ),
                      ),
                    // Hex badge bottom-left
                    Positioned(
                      left: 14,
                      bottom: 16,
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
                              Flexible(
                                child: Text(
                                  '${p.totalDrops} drops · '
                                  '${_timeAgo(p.updatedAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
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

// ── Relative time ─────────────────────────────────────────────────────────────
/// "just now", "5 min ago", "3 h ago", "2 days ago", or the date.
String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${time.day}/${time.month}/${time.year}';
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
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Living room wall',
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
            const SizedBox(height: 8),
            const Text(
              'You can rename it later.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
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
