import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/color_project.dart';

// ── Design Tokens ──────────────────────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFF0A0A1A);
  static const surface = Color(0xFF12122A);
  static const card = Color(0xFF1A1A38);
  static const cardBright = Color(0xFF222248);

  static const accent1 = Color(0xFF8B5CF6);
  static const accent2 = Color(0xFF06B6D4);
  static const accent3 = Color(0xFFEC4899);

  static const textPrimary = Color(0xFFF1F0FF);
  static const textSecondary = Color(0xFF9898CC);
  static const border = Color(0xFF2C2C5E);
  static const divider = Color(0xFF1E1E40);

  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const yellow = Color(0xFFF59E0B);

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [accent1, accent2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1E45), Color(0xFF16163A)],
      );
}

// ── Background Painter (shared) ───────────────────────────────────────────────
class BgPainter extends CustomPainter {
  final Animation<double> anim;
  BgPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;

    void orb(double cx, double cy, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha(38), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    orb(
      size.width * (0.15 + 0.06 * math.sin(t * 2 * math.pi)),
      size.height * (0.2 + 0.04 * math.cos(t * 2 * math.pi)),
      size.width * 0.55,
      const Color(0xFF8B5CF6),
    );
    orb(
      size.width * (0.8 + 0.05 * math.cos(t * 2 * math.pi)),
      size.height * (0.72 + 0.05 * math.sin(t * 2 * math.pi)),
      size.width * 0.5,
      const Color(0xFF06B6D4),
    );
    orb(
      size.width * 0.5,
      size.height * (0.45 + 0.03 * math.sin(t * 2 * math.pi + 1)),
      size.width * 0.35,
      const Color(0xFFEC4899),
    );
  }

  @override
  bool shouldRepaint(BgPainter old) => true;
}

// ── Mixer Page ────────────────────────────────────────────────────────────────
class MixerPage extends StatefulWidget {
  final ColorProject project;
  final bool isNew;

  const MixerPage({super.key, required this.project, this.isNew = false});

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> with TickerProviderStateMixin {
  late Map<String, int> _colorCounts;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  bool _hasChanges = false;

final List<_ColorOption> _primaryColors = [
  _ColorOption('Red', AppColors.red, Icons.water_drop),
  _ColorOption('Blue', AppColors.blue, Icons.water_drop),
  _ColorOption('Yellow', AppColors.yellow, Icons.water_drop),
  _ColorOption('White', Colors.white, Icons.circle_outlined),
  _ColorOption('Black', Colors.black, Icons.circle),
];

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _colorCounts = Map.from(widget.project.colorCounts);
    _nameController = TextEditingController(text: widget.project.name);
    _notesController = TextEditingController(text: widget.project.notes ?? '');

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
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int get _drops => _colorCounts.values.fold(0, (s, v) => s + v);

  int _ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;

  Color get _mixedColor {
    if (_drops == 0) return Colors.white;
    int rs = 0, gs = 0, bs = 0;
    for (final opt in _primaryColors) {
      final cnt = _colorCounts[opt.name] ?? 0;
      rs += _ch(opt.color, 16) * cnt;
      gs += _ch(opt.color, 8) * cnt;
      bs += _ch(opt.color, 0) * cnt;
    }
    return Color.fromARGB(255, (rs / _drops).round(), (gs / _drops).round(),
        (bs / _drops).round());
  }

  int _getRed(Color c) => _ch(c, 16);
  int _getGreen(Color c) => _ch(c, 8);
  int _getBlue(Color c) => _ch(c, 0);

Map<String, int> _mixPct() {
  if (_drops == 0) {
    return {
      'Red': 0,
      'Blue': 0,
      'Yellow': 0,
      'White': 0,
      'Black': 0,
    };
  }

  return {
    'Red': ((_colorCounts['Red'] ?? 0) * 100 / _drops).round(),
    'Blue': ((_colorCounts['Blue'] ?? 0) * 100 / _drops).round(),
    'Yellow': ((_colorCounts['Yellow'] ?? 0) * 100 / _drops).round(),
    'White': ((_colorCounts['White'] ?? 0) * 100 / _drops).round(),
    'Black': ((_colorCounts['Black'] ?? 0) * 100 / _drops).round(),
  };
}

  String get _hexString {
    final c = _mixedColor;
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  String _colorLabel(Color color) {
    int r = _getRed(color), g = _getGreen(color), b = _getBlue(color);
   final refs = {
      'Red': [239, 68, 68],
      'Blue': [59, 130, 246],
      'Yellow': [245, 158, 11],
      'Orange': [249, 115, 22],
      'Green': [34, 197, 94],
      'Purple': [168, 85, 247],
      'Pink': [236, 72, 153],
      'Brown': [120, 53, 15],
      'Gray': [148, 163, 184],
      'White': [255, 255, 255],
      'Black': [0, 0, 0],
    };
    String nearest = 'Custom';
    int best = 9999;
    refs.forEach((name, rgb) {
      final d = (r - rgb[0]).abs() + (g - rgb[1]).abs() + (b - rgb[2]).abs();
      if (d < best) {
        best = d;
        nearest = name;
      }
    });
    return nearest;
  }

  void _changeDrop(_ColorOption opt, int delta) {
    setState(() {
      final cur = _colorCounts[opt.name] ?? 0;
      final upd = (cur + delta).clamp(0, 30);
      if (upd != cur) {
        _colorCounts[opt.name] = upd;
        _hasChanges = true;
      }
    });
  }

  void _resetMixer() {
    setState(() {
      _colorCounts.updateAll((k, v) => 0);
      _hasChanges = true;
    });
  }

  Future<void> _copyInfo() async {
    final c = _mixedColor;
    final info =
        'Project: ${_nameController.text}\nRGB: (${_getRed(c)}, ${_getGreen(c)}, ${_getBlue(c)})\nHex: $_hexString\nDrops: $_drops';
    await Clipboard.setData(ClipboardData(text: info));
    if (!mounted) return;
    _showSnack('Color info copied!', Icons.check_circle_rounded);
  }

  void _showSnack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(children: [
        Icon(icon, color: AppColors.accent2, size: 20),
        const SizedBox(width: 10),
        Text(msg,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  void _saveProject() {
    final updated = widget.project.copyWith(
      name: _nameController.text.trim().isEmpty
          ? 'Untitled Mix'
          : _nameController.text.trim(),
      colorCounts: Map.from(_colorCounts),
      notes:
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _DiscardDialog(),
    );
    return result ?? false;
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
                        horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildNameField(),
                        const SizedBox(height: 20),
                        _buildColorPreview(),
                        const SizedBox(height: 28),
                        _buildSectionTitle(
                            'Primary Colors', Icons.palette_rounded),
                        const SizedBox(height: 14),
                        _buildPrimaryColors(),
                        const SizedBox(height: 28),
                        _buildSectionTitle(
                            'Mix Analysis', Icons.analytics_rounded),
                        const SizedBox(height: 14),
                        _buildAnalysisCard(),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Notes', Icons.notes_rounded),
                        const SizedBox(height: 14),
                        _buildNotesField(),
                        const SizedBox(height: 28),
                        _buildActions(),
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
      backgroundColor: AppColors.bg.withAlpha(200),
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
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 16),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: AppColors.border.withAlpha(120), width: 1),
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
              color: AppColors.textSecondary, fontWeight: FontWeight.w400),
          prefixIcon: ShaderMask(
            shaderCallback: (r) => AppColors.accentGradient.createShader(r),
            child: const Icon(Icons.drive_file_rename_outline_rounded,
                color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          hintText: 'Add notes about this mix…',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 42),
            child: Icon(Icons.notes_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Color Preview ─────────────────────────────────────────────────────────
  Widget _buildColorPreview() {
    final isDark = _mixedColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      children: [
        Center(
          child: ScaleTransition(
            scale: _pulseAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mixedColor,
                boxShadow: [
                  BoxShadow(
                      color: _mixedColor.withAlpha(110),
                      blurRadius: 60,
                      spreadRadius: 10),
                  BoxShadow(
                      color: _mixedColor.withAlpha(55),
                      blurRadius: 100,
                      spreadRadius: 20),
                ],
              ),
              child: ClipOval(
                child: Stack(fit: StackFit.expand, children: [
                  Positioned(
                    top: -30,
                    left: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Colors.white.withAlpha(50),
                          Colors.transparent
                        ]),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                        child: Text(_drops == 0
                            ? 'Canvas'
                            : _colorLabel(_mixedColor)),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            color: textColor.withAlpha(180),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        child: Text(_drops == 0 ? 'Add drops' : _hexString),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildRgbRow(),
      ],
    );
  }

  Widget _buildRgbRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('R', _getRed(_mixedColor), const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        _chip('G', _getGreen(_mixedColor), const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        _chip('B', _getBlue(_mixedColor), const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _drops > 0 ? _copyInfo : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(_hexString,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, int val, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label ',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text('$val',
              key: ValueKey(val),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
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
      Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2)),
    ]);
  }

  // ── Primary Colors ────────────────────────────────────────────────────────
  Widget _buildPrimaryColors() {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 20) / 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _primaryColors.map((opt) {
          final count = _colorCounts[opt.name] ?? 0;
          return SizedBox(
            width: itemWidth,
            child: _ColorCard(
              option: opt,
              count: count,
              onAdd: () => _changeDrop(opt, 1),
              onRemove: () => _changeDrop(opt, -1),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── Analysis Card ─────────────────────────────────────────────────────────
  Widget _buildAnalysisCard() {
    final pct = _mixPct();
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
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mixedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                    color: _mixedColor.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Mix',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _drops == 0
                    ? 'No color added'
                    : '${_colorLabel(_mixedColor)}  •  $_drops drops',
                key: ValueKey(_drops),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 18),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 18),
        _bar('Red', pct['Red'] ?? 0, const Color(0xFFEF4444)),
        const SizedBox(height: 10),
        _bar('Blue', pct['Blue'] ?? 0, const Color(0xFF3B82F6)),
        const SizedBox(height: 10),
        _bar('Yellow', pct['Yellow'] ?? 0, const Color(0xFFF59E0B)),
        const SizedBox(height: 10),
        _bar('White', pct['White'] ?? 0, Colors.grey.shade300),
        const SizedBox(height: 10),
        _bar('Black', pct['Black'] ?? 0, Colors.black),
        const SizedBox(height: 18),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(
              child: _infoTile('RGB',
                  '${_getRed(_mixedColor)}, ${_getGreen(_mixedColor)}, ${_getBlue(_mixedColor)}',
                  Icons.color_lens_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _infoTile('Hex', _hexString, Icons.tag_rounded)),
        ]),
      ]),
    );
  }

  Widget _bar(String label, int pct, Color color) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
        Text('$pct%',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
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
    ]);
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: AppColors.accent2),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(children: [
      Expanded(
          child: _GradientButton(
        label: 'Reset',
        icon: Icons.refresh_rounded,
        enabled: _drops > 0,
        onTap: _resetMixer,
      )),
      const SizedBox(width: 12),
      Expanded(
          child: _OutlineButton(
        label: 'Copy Info',
        icon: Icons.copy_all_rounded,
        enabled: _drops > 0,
        onTap: _copyInfo,
      )),
    ]);
  }
}

// ── Color Card ────────────────────────────────────────────────────────────────
class _ColorCard extends StatefulWidget {
  final _ColorOption option;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ColorCard(
      {required this.option,
      required this.count,
      required this.onAdd,
      required this.onRemove});

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
        vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOut));
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
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: opt.color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                    color: opt.color.withAlpha(70),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(opt.icon, color: tc.withAlpha(200), size: 20),
                const SizedBox(height: 3),
                Text(opt.name,
                    style: TextStyle(
                        color: tc,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ]),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text('${widget.count}',
                    key: ValueKey(widget.count),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1)),
              ),
              const Text('drops',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _DropBtn(
                        icon: Icons.remove_rounded,
                        color: opt.color,
                        enabled: widget.count > 0,
                        onTap: () {
                          _c.forward().then((_) => _c.reverse());
                          widget.onRemove();
                        })),
                const SizedBox(width: 5),
                Expanded(
                    child: _DropBtn(
                        icon: Icons.add_rounded,
                        color: opt.color,
                        enabled: widget.count < 30,
                        filled: true,
                        onTap: () {
                          _c.forward().then((_) => _c.reverse());
                          widget.onAdd();
                        })),
              ]),
            ]),
          ),
        ]),
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

  const _DropBtn(
      {required this.icon,
      required this.color,
      required this.enabled,
      required this.onTap,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: filled ? color : color.withAlpha(28),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: filled ? Colors.transparent : color.withAlpha(70)),
          ),
          child: Icon(icon,
              color: filled
                  ? (color.computeLuminance() < 0.5
                      ? Colors.white
                      : Colors.black87)
                  : color,
              size: 17),
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

  const _GradientButton(
      {required this.label,
      required this.icon,
      required this.enabled,
      required this.onTap});

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
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
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
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
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

  const _OutlineButton(
      {required this.label,
      required this.icon,
      required this.enabled,
      required this.onTap});

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
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
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
                  Text(widget.label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
          ),
        ),
      ),
    );
  }
}

// ── Discard Dialog ────────────────────────────────────────────────────────────
class _DiscardDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Discard changes?',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your unsaved changes will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(children: [
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
                    child: Text('Keep Editing',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600))),
              ),
            )),
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
                      color: const Color(0xFFEF4444).withAlpha(60)),
                ),
                child: const Center(
                    child: Text('Discard',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700))),
              ),
            )),
          ]),
        ]),
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
