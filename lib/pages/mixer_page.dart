import 'dart:isolate';
import 'dart:ui' show lerpDouble, FontFeature;
import 'package:admob_kit/admob_kit.dart';
import 'package:colormixer/widget/adaptive_banner_ad.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/color_project.dart';
import '../ui/app_colors.dart';
import '../ui/bg_painter.dart';

// ── Mixer Page ────────────────────────────────────────────────────────────────
class MixerPage extends StatefulWidget {
  final ColorProject project;
  final bool isNew;

  const MixerPage({super.key, required this.project, this.isNew = false});

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _maxDrops = 30;

  late Map<String, int> _colorCounts;
  final List<_ColorOption> _customColors = [];
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  bool _hasChanges = false;

  static final List<_ColorOption> _primaryColors = [
    for (final e in ColorProject.primaries.entries)
      _ColorOption(e.key, e.value, switch (e.key) {
        'White' => Icons.circle_outlined,
        'Black' => Icons.circle,
        _ => Icons.water_drop,
      }),
  ];

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _colorCounts = Map.from(widget.project.colorCounts);
    widget.project.customColors.forEach((name, argb) {
      _customColors.add(
        _ColorOption(name, Color(argb), Icons.colorize_rounded),
      );
    });
    _nameController = TextEditingController(text: widget.project.name);
    _notesController = TextEditingController(text: widget.project.notes ?? '');
    // A brand-new project isn't saved yet, so leaving asks to save it.
    _hasChanges = widget.isNew;
    // Load now so it is ready by the time the user saves.
    InterstitialAdManager.load();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<_ColorOption> get _allColors => [..._primaryColors, ..._customColors];

  Map<String, int> get _customMap => {
    for (final c in _customColors) c.name: c.color.toARGB32(),
  };

  int get _drops => _colorCounts.values.fold(0, (s, v) => s + v);

  int _ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;

  Color get _mixedColor => ColorProject.mix(_colorCounts, _customMap);

  int _getRed(Color c) => _ch(c, 16);
  int _getGreen(Color c) => _ch(c, 8);
  int _getBlue(Color c) => _ch(c, 0);

  String get _hexString => ColorProject.hexOf(_mixedColor);

  String _colorLabel(Color color) => ColorProject.labelOf(color);

  void _changeDrop(_ColorOption opt, int delta) {
    final cur = _colorCounts[opt.name] ?? 0;
    final upd = (cur + delta).clamp(0, _maxDrops);
    if (upd == cur) {
      if (delta > 0) {
        _showSnack(
          'Max $_maxDrops drops per color',
          Icons.info_outline_rounded,
        );
      }
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _colorCounts[opt.name] = upd;
      _hasChanges = true;
    });
  }

  void _resetMixer() {
    final before = Map<String, int>.from(_colorCounts);
    setState(() {
      _colorCounts.updateAll((k, v) => 0);
      _hasChanges = true;
    });
    _showSnack(
      'Mix cleared',
      Icons.refresh_rounded,
      actionLabel: 'UNDO',
      onAction: () => setState(() {
        _colorCounts
          ..clear()
          ..addAll(before);
      }),
    );
  }

  Future<void> _copyInfo() async {
    final c = _mixedColor;
    final recipe = _allColors
        .where((o) => (_colorCounts[o.name] ?? 0) > 0)
        .map((o) => '${o.name}: ${_colorCounts[o.name]}')
        .join(', ');
    final info =
        'Project: ${_nameController.text}\n'
        'Recipe: $recipe\n'
        'RGB: (${_getRed(c)}, ${_getGreen(c)}, ${_getBlue(c)})\n'
        'Hex: $_hexString';
    await Clipboard.setData(ClipboardData(text: info));
    if (!mounted) return;
    _showSnack('Color info copied!', Icons.check_circle_rounded);
  }

  void _showSnack(
    String msg,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: AppColors.accent2,
                  onPressed: onAction ?? () {},
                ),
          content: Row(
            children: [
              Icon(icon, color: AppColors.accent2, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _saveProject() {
    final names = _allColors.map((o) => o.name).toSet();
    final updated = widget.project.copyWith(
      name: _nameController.text.trim().isEmpty
          ? 'Untitled Mix'
          : _nameController.text.trim(),
      colorCounts: {
        for (final e in _colorCounts.entries)
          if (names.contains(e.key)) e.key: e.value,
      },
      customColors: _customMap,
      notes: _notesController.text.trim(),
    );
    _hasChanges = false;
    AdManager.showInterstitial();
    Navigator.of(context).pop(updated);
  }

  // ── Custom colors ──────────────────────────────────────────────────────────
  void _addCustomColor(Color color) {
    final opaque = color.withAlpha(255);
    final name = ColorProject.hexOf(opaque);
    if (_allColors.any((o) => o.name == name)) {
      _showSnack('$name is already in your palette', Icons.info_outline);
      return;
    }
    setState(() {
      _customColors.add(_ColorOption(name, opaque, Icons.colorize_rounded));
      _colorCounts[name] = 1;
      _hasChanges = true;
    });
    _showSnack('Added $name with 1 drop', Icons.check_circle_rounded);
  }

  void _removeCustomColor(_ColorOption opt) {
    final index = _customColors.indexOf(opt);
    final count = _colorCounts[opt.name] ?? 0;
    setState(() {
      _customColors.remove(opt);
      _colorCounts.remove(opt.name);
      _hasChanges = true;
    });
    _showSnack(
      '${opt.name} removed',
      Icons.delete_outline_rounded,
      actionLabel: 'UNDO',
      onAction: () => setState(() {
        _customColors.insert(index.clamp(0, _customColors.length), opt);
        _colorCounts[opt.name] = count;
      }),
    );
  }

  Future<void> _showAddColorSheet() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  'Add a color',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SheetOption(
                icon: Icons.palette_rounded,
                title: 'Pick from color wheel',
                subtitle: 'Choose any exact color',
                onTap: () => Navigator.of(ctx).pop('wheel'),
              ),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take a photo',
                subtitle: 'Match a color from real life',
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Pick a color from any picture',
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    switch (source) {
      case 'wheel':
        await _pickCustomColor();
      case 'camera':
        await _pickColorFromImage(ImageSource.camera);
      case 'gallery':
        await _pickColorFromImage(ImageSource.gallery);
    }
  }

  Future<void> _pickCustomColor() async {
    Color selected = AppColors.accent1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add color'),
          ),
        ],
      ),
    );
    if (ok == true) _addCustomColor(selected);
  }

  Future<void> _pickColorFromImage(ImageSource source) async {
    final XFile? file;
    try {
      // Downscaled on pick: plenty for color sampling and fast to decode.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (e) {
      _showSnack('Could not open the camera or gallery', Icons.error_outline);
      return;
    }
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    // Apply EXIF rotation so pixels line up with the photo as displayed.
    final decoded = await Isolate.run(() {
      final image = img.decodeImage(bytes);
      return image == null ? null : img.bakeOrientation(image);
    });
    if (!mounted) return;
    if (decoded == null) {
      _showSnack('Could not read that image', Icons.error_outline);
      return;
    }

    final color = await showDialog<Color>(
      context: context,
      builder: (_) => _ImageColorPickerDialog(bytes: bytes, image: decoded),
    );
    if (color != null) _addCustomColor(color);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<_LeaveChoice>(
      context: context,
      builder: (_) => const _DiscardDialog(),
    );
    if (result == _LeaveChoice.save) {
      _saveProject();
      return false; // _saveProject already navigated back.
    }
    return result == _LeaveChoice.discard;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _onWillPop();
        if (ok && mounted) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            CustomPaint(
              painter: BgPainter(_rotateController),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([_buildNameField()]),
                    ),
                  ),
                  // The mix stays pinned (shrinking) while you scroll to the
                  // colors, so every drop's effect is visible immediately.
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _MixHeaderDelegate(
                      minHeight: 84,
                      maxHeight: 176,
                      builder: _buildMixHeader,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionTitle(
                                'Colors',
                                Icons.palette_rounded,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _showAddColorSheet,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent1,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Add color',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _drops == 0
                              ? 'Tap + on a color to add drops.'
                              : 'Tap + / − to adjust. Up to $_maxDrops drops '
                                    'per color.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildPrimaryColors(),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Recipe', Icons.analytics_rounded),
                        const SizedBox(height: 14),
                        _buildAnalysisCard(),
                        const SizedBox(height: 28),
                        _buildNotesField(),
                        const SizedBox(height: 28),
                        _buildActions(),
                        const SizedBox(height: 12),
                        const InlineAdCard(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () async {
          final nav = Navigator.of(context);
          final ok = _hasChanges ? await _onWillPop() : true;
          if (ok && mounted) nav.pop();
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 16,
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (r) => AppColors.accentGradient.createShader(r),
        child: Text(
          widget.isNew ? 'New Project' : 'Edit Mix',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: _saveProject,
          child: Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withAlpha(120),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Name Field ────────────────────────────────────────────────────────────
  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _nameController,
        onChanged: (_) => setState(() => _hasChanges = true),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Project name…',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: ShaderMask(
            shaderCallback: (r) => AppColors.accentGradient.createShader(r),
            child: const Icon(
              Icons.drive_file_rename_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ── Notes Field ───────────────────────────────────────────────────────────
  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _notesController,
        onChanged: (_) => setState(() => _hasChanges = true),
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Add notes about this mix…',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 42),
            child: Icon(
              Icons.notes_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Mix Header (pinned, shrinks on scroll) ────────────────────────────────
  /// [t] goes from 0 (fully expanded) to 1 (collapsed while scrolling).
  Widget _buildMixHeader(BuildContext context, double t) {
    final color = _mixedColor;
    final empty = _drops == 0;
    final swatch = lerpDouble(112, 52, t)!;
    final detailsOpacity = (1 - t * 2).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, lerpDouble(12, 10, t)!, 20, 10),
      decoration: BoxDecoration(
        // Solid once scrolling starts, so content never shows through.
        color: AppColors.bg.withAlpha(((t * 4).clamp(0.0, 1.0) * 255).round()),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withAlpha((t * 160).round()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Swatch
          ScaleTransition(
            scale: empty || t > 0.5
                ? const AlwaysStoppedAnimation(1.0)
                : _pulseAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: swatch,
              height: swatch,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: empty ? AppColors.card : color,
                border: Border.all(
                  color: empty ? AppColors.border : Colors.white.withAlpha(40),
                  width: empty ? 2 : 1,
                ),
                boxShadow: empty
                    ? null
                    : [
                        BoxShadow(
                          color: color.withAlpha(110),
                          blurRadius: lerpDouble(40, 14, t)!,
                          spreadRadius: lerpDouble(4, 0, t)!,
                        ),
                      ],
              ),
              child: empty
                  ? Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.textSecondary,
                      size: swatch * 0.36,
                    )
                  : null,
            ),
          ),
          SizedBox(width: lerpDouble(20, 14, t)),
          // Name, hex, RGB and drops
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empty ? 'Empty mix' : _colorLabel(color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: lerpDouble(24, 17, t),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: lerpDouble(8, 4, t)),
                Row(
                  children: [
                    _HexChip(
                      hex: empty ? '—' : _hexString,
                      onTap: empty ? null : _copyInfo,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        empty
                            ? 'No drops yet'
                            : '$_drops ${_drops == 1 ? 'drop' : 'drops'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detailsOpacity > 0) ...[
                  SizedBox(height: 10 * detailsOpacity),
                  Opacity(
                    opacity: detailsOpacity,
                    child: Row(
                      children: [
                        _rgbDot('R', _getRed(color), AppColors.red),
                        _rgbDot('G', _getGreen(color), const Color(0xFF22C55E)),
                        _rgbDot('B', _getBlue(color), AppColors.blue),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rgbDot(String label, int value, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Primary Colors ────────────────────────────────────────────────────────
  Widget _buildPrimaryColors() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final opt in _allColors)
              SizedBox(
                width: itemWidth,
                child: _ColorCard(
                  option: opt,
                  count: _colorCounts[opt.name] ?? 0,
                  maxCount: _maxDrops,
                  onAdd: () => _changeDrop(opt, 1),
                  onRemove: () => _changeDrop(opt, -1),
                  onDelete: _customColors.contains(opt)
                      ? () => _removeCustomColor(opt)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Analysis Card ─────────────────────────────────────────────────────────
  Widget _buildAnalysisCard() {
    final drops = _drops;
    final used = _allColors
        .where((o) => (_colorCounts[o.name] ?? 0) > 0)
        .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (used.isEmpty)
            const Text(
              'Your recipe will appear here once you add some drops.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            for (final (i, opt) in used.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              _bar(
                '${opt.name} · ${_colorCounts[opt.name]} '
                '${_colorCounts[opt.name] == 1 ? 'drop' : 'drops'}',
                ((_colorCounts[opt.name] ?? 0) * 100 / drops).round(),
                opt.color,
              ),
            ],
        ],
      ),
    );
  }

  Widget _bar(String label, int pct, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _GradientButton(
            label: 'Reset',
            icon: Icons.refresh_rounded,
            enabled: _drops > 0,
            onTap: _resetMixer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OutlineButton(
            label: 'Copy Info',
            icon: Icons.copy_all_rounded,
            enabled: _drops > 0,
            onTap: _copyInfo,
          ),
        ),
      ],
    );
  }
}

// ── Color Card ────────────────────────────────────────────────────────────────
class _ColorCard extends StatefulWidget {
  final _ColorOption option;
  final int count;
  final int maxCount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Removes the color from the palette (custom colors only).
  final VoidCallback? onDelete;

  const _ColorCard({
    required this.option,
    required this.count,
    required this.maxCount,
    required this.onAdd,
    required this.onRemove,
    this.onDelete,
  });

  @override
  State<_ColorCard> createState() => _ColorCardState();
}

class _ColorCardState extends State<_ColorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    final dark = opt.color.computeLuminance() < 0.5;
    final tc = dark ? Colors.white : Colors.black87;

    return ScaleTransition(
      scale: _s,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: opt.color.withAlpha(28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: opt.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: opt.color.withAlpha(70),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.icon, color: tc.withAlpha(200), size: 20),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            opt.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tc,
                              fontWeight: FontWeight.w700,
                              fontSize: opt.name.startsWith('#') ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton(
                        onPressed: widget.onDelete,
                        tooltip: 'Remove color',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withAlpha(40),
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                        ),
                        icon: Icon(Icons.close_rounded, color: tc),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '${widget.count}',
                      key: ValueKey(widget.count),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  const Text(
                    'drops',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DropBtn(
                          icon: Icons.remove_rounded,
                          color: opt.color,
                          enabled: widget.count > 0,
                          onTap: () {
                            _c.forward().then((_) => _c.reverse());
                            widget.onRemove();
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _DropBtn(
                          icon: Icons.add_rounded,
                          color: opt.color,
                          enabled: widget.count < widget.maxCount,
                          filled: true,
                          onTap: () {
                            _c.forward().then((_) => _c.reverse());
                            widget.onAdd();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drop Button ───────────────────────────────────────────────────────────────
class _DropBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  const _DropBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: filled ? color : color.withAlpha(28),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: filled ? Colors.transparent : color.withAlpha(70),
            ),
          ),
          child: Icon(
            icon,
            color: filled
                ? (color.computeLuminance() < 0.5
                      ? Colors.white
                      : Colors.black87)
                : color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
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
      end: 0.95,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: AppColors.accent1.withAlpha(80),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

// ── Outline Button ────────────────────────────────────────────────────────────
class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton>
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
      end: 0.95,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: AppColors.accent2, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

// ── Leave Dialog ──────────────────────────────────────────────────────────────
enum _LeaveChoice { save, discard }

class _DiscardDialog extends StatelessWidget {
  const _DiscardDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent1.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_rounded,
                  color: AppColors.accent1,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Save your changes?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "If you leave without saving, this mix will be lost.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.save),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent1,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Keep editing'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_LeaveChoice.discard),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.red,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text(
                      'Discard',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

// ── Add-color sheet option ────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
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
    );
  }
}

// ── Pick a color from a photo ─────────────────────────────────────────────────
class _ImageColorPickerDialog extends StatefulWidget {
  final Uint8List bytes;
  final img.Image image;

  const _ImageColorPickerDialog({required this.bytes, required this.image});

  @override
  State<_ImageColorPickerDialog> createState() =>
      _ImageColorPickerDialogState();
}

class _ImageColorPickerDialogState extends State<_ImageColorPickerDialog> {
  Offset? _marker; // In displayed-image coordinates.
  Color? _color;

  void _sample(Offset local, Size shown) {
    final image = widget.image;
    final dx = local.dx.clamp(0.0, shown.width - 1);
    final dy = local.dy.clamp(0.0, shown.height - 1);
    final x = (dx / shown.width * image.width).floor().clamp(
      0,
      image.width - 1,
    );
    final y = (dy / shown.height * image.height).floor().clamp(
      0,
      image.height - 1,
    );
    final p = image.getPixel(x, y);
    HapticFeedback.selectionClick();
    setState(() {
      _marker = Offset(dx, dy);
      _color = Color.fromARGB(255, p.r.toInt(), p.g.toInt(), p.b.toInt());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tap or drag on the photo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick the exact spot whose color you want.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fit the image inside the space, keeping its aspect ratio,
                  // so taps map exactly onto its pixels.
                  final aspect = widget.image.width / widget.image.height;
                  var w = constraints.maxWidth;
                  var h = w / aspect;
                  final maxH = MediaQuery.sizeOf(context).height * 0.5;
                  if (h > maxH) {
                    h = maxH;
                    w = h * aspect;
                  }
                  final shown = Size(w, h);
                  return Center(
                    child: GestureDetector(
                      onTapDown: (d) => _sample(d.localPosition, shown),
                      onPanUpdate: (d) => _sample(d.localPosition, shown),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.memory(
                                  widget.bytes,
                                  fit: BoxFit.fill,
                                  gaplessPlayback: true,
                                ),
                              ),
                              if (_marker != null)
                                Positioned(
                                  left: _marker!.dx - 14,
                                  top: _marker!.dy - 14,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color ?? AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    color == null
                        ? 'No color selected yet'
                        : '${ColorProject.labelOf(color)} · '
                              '${ColorProject.hexOf(color)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: color == null
                        ? null
                        : () => Navigator.of(context).pop(color),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent1,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Add color',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

/// Pinned header that hands its builder how collapsed it is (0 → 1).
class _MixHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget Function(BuildContext context, double t) builder;

  const _MixHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
    return SizedBox.expand(child: builder(context, t));
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  // The header shows live mix state, so always rebuild with the page.
  @override
  bool shouldRebuild(covariant _MixHeaderDelegate oldDelegate) => true;
}

/// Tappable hex value that copies the mix info.
class _HexChip extends StatelessWidget {
  final String hex;
  final VoidCallback? onTap;

  const _HexChip({required this.hex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hex,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: AppColors.accent2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Color Option ──────────────────────────────────────────────────────────────
class _ColorOption {
  final String name;
  final Color color;
  final IconData icon;

  const _ColorOption(this.name, this.color, this.icon);
}
