import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../community/presentation/providers/communities_provider.dart';
import '../../domain/sos_alert_model.dart';
import '../providers/sos_notifier.dart';

// ─── Constants ─────────────────────────────────────────────────────────────────

const _accentEmerald = Color(0xFF22C55E);
const _activeBg = Color(0xFF1A0A0A);
const _activeBanner = Color(0xFF2A0A0A);

// ─── SOS Page ────────────────────────────────────────────────────────────────

class SosPage extends ConsumerStatefulWidget {
  const SosPage({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<SosPage> createState() => _SosPageState();
}

class _SosPageState extends ConsumerState<SosPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _holdController;

  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    // Pulsing rings — loops every 2s
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Hold progress — fills in 2s
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldCompleted();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() => _isHolding = true);
    _holdController.forward(from: 0);
  }

  void _onHoldEnd() {
    if (_holdController.status != AnimationStatus.completed) {
      setState(() => _isHolding = false);
      _holdController.reset();
      _showHoldTip();
    }
  }

  void _showHoldTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'استمر في الضغط لمدة 2 ثانية',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onHoldCompleted() async {
    setState(() => _isHolding = false);
    _holdController.reset();
    await ref.read(sosNotifierProvider.notifier).triggerSOS();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosNotifierProvider);
    return switch (state.mode) {
      SosScreenMode.idle || SosScreenMode.triggering => _buildIdleScreen(state),
      SosScreenMode.active => _buildActiveScreen(state),
      SosScreenMode.resolved => _buildEndScreen(
        resolved: true,
        message: 'تم حل النداء',
        by: state.resolvedBy,
      ),
      SosScreenMode.cancelled => _buildEndScreen(
        resolved: false,
        message: 'تم إلغاء النداء',
        by: state.resolvedBy,
      ),
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IDLE SCREEN
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildIdleScreen(SosState state) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'نجدة',
          textDirection: TextDirection.rtl,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),

                      // ── Pulsing SOS button ─────────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onLongPressStart: (_) => _onHoldStart(),
                          onLongPressEnd: (_) => _onHoldEnd(),
                          onLongPressCancel: _onHoldEnd,
                          child: _PulsingSosButton(
                            pulseController: _pulseController,
                            holdController: _holdController,
                            isHolding: _isHolding,
                            isTriggering: state.isTriggering,
                            sosColor: context.semantic.sos,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Error message ──────────────────────────────────────────────
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: context.semantic.sosContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: context.semantic.sos.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              state.error!,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: context.text.bodySmall?.copyWith(
                                color: context.semantic.sos,
                              ),
                            ),
                          ),
                        ),

                      if (state.error != null) const SizedBox(height: 16),

                      // ── Severity selector ──────────────────────────────────────────
                      Text(
                        'مستوى الطوارئ',
                        textDirection: TextDirection.rtl,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.semantic.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: SosSeverity.values.map((s) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _SeverityChip(
                              label: s.label,
                              severity: s,
                              isSelected: state.severity == s,
                              onTap: () => ref
                                  .read(sosNotifierProvider.notifier)
                                  .setSeverity(s),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // ── Community dropdown ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'إرسال إلى المجتمع',
                              textDirection: TextDirection.rtl,
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.semantic.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _CommunityDropdown(
                              selectedId: state.selectedCommunityId,
                              onChanged: (id) => ref
                                  .read(sosNotifierProvider.notifier)
                                  .setCommunityId(id),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Optional message ───────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          maxLength: 200,
                          onChanged: (v) => ref
                              .read(sosNotifierProvider.notifier)
                              .setMessage(v),
                          decoration: InputDecoration(
                            hintText: 'رسالة إضافية (اختياري)',
                            hintTextDirection: TextDirection.rtl,
                            counterText: '',
                            filled: true,
                            fillColor: context.semantic.surfaceInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: context.semantic.borderSubtle,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: context.semantic.borderSubtle,
                              ),
                            ),
                          ),
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ── Hint ──────────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'اضغط مطولاً على الزر لمدة 2 ثانية لإرسال النداء',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: context.text.labelSmall?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACTIVE SCREEN
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildActiveScreen(SosState state) {
    final sosColor = context.semantic.sos;
    return Scaffold(
      backgroundColor: _activeBg,
      appBar: AppBar(
        backgroundColor: _activeBanner,
        elevation: 0,
        title: const Text(
          'نداء نشط',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _ElapsedTimerText(seconds: state.elapsedSeconds),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Status banner ──────────────────────────────────────────────
                      Container(
                        color: sosColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(
                              Icons.crisis_alert_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'نداء طوارئ نشط',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _SeverityBadge(
                              severity:
                                  state.activeAlert?.severity ?? 'Standard',
                            ),
                          ],
                        ),
                      ),

                      if (state.activeAlert != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _AffectedCommunitiesLabel(
                            alert: state.activeAlert!,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Elapsed time ───────────────────────────────────────────────
                      Text(
                        'مضى على النداء',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatElapsed(state.elapsedSeconds),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Mini map ───────────────────────────────────────────────────
                      if (state.currentLat != null && state.currentLng != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 180,
                              child: _SosMap(
                                lat: state.currentLat!,
                                lng: state.currentLng!,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1010),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(color: sosColor),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Location last update ───────────────────────────────────────
                      _LocationUpdateRow(
                        lastUpdated: state.locationLastUpdated,
                      ),

                      const SizedBox(height: 16),

                      // ── SignalR status card ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SosStatusCard(alert: state.activeAlert),
                      ),

                      const Spacer(),

                      // ── Cancel button ──────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showCancelDialog(state.activeAlert?.id ?? ''),
                          icon: Icon(Icons.cancel_outlined, color: sosColor),
                          label: Text(
                            'إلغاء النداء',
                            style: TextStyle(
                              color: sosColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: sosColor, width: 1.5),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RESOLVED / CANCELLED SCREEN
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEndScreen({
    required bool resolved,
    required String message,
    String? by,
  }) {
    return Scaffold(
      backgroundColor: _activeBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                resolved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 80,
                color: resolved ? _accentEmerald : Colors.white60,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (by != null && by.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'بواسطة: $by',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () =>
                    ref.read(sosNotifierProvider.notifier).resetToIdle(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _showCancelDialog(String alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0A0A),
        title: const Text(
          'إلغاء النداء',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد إلغاء نداء الطوارئ؟',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.semantic.sos,
            ),
            child: const Text(
              'نعم، إلغاء',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(sosNotifierProvider.notifier).cancelSOS();
    }
  }

  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Pulsing SOS button ──────────────────────────────────────────────────────

class _PulsingSosButton extends StatelessWidget {
  const _PulsingSosButton({
    required this.pulseController,
    required this.holdController,
    required this.isHolding,
    required this.isTriggering,
    required this.sosColor,
  });

  final AnimationController pulseController;
  final AnimationController holdController;
  final bool isHolding;
  final bool isTriggering;
  final Color sosColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Pulsing rings ────────────────────────────────────────────────
          ...List.generate(3, (i) {
            final delay = i * 0.33;
            return AnimatedBuilder(
              animation: pulseController,
              builder: (context, _) {
                final raw = ((pulseController.value - delay) % 1.0);
                final t = raw < 0 ? raw + 1.0 : raw;
                final scale = 1.0 + t * 0.7;
                final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.5;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sosColor.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            );
          }),

          // ── Hold progress ring ───────────────────────────────────────────
          if (isHolding)
            AnimatedBuilder(
              animation: holdController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: _HoldProgressPainter(holdController.value),
                );
              },
            ),

          // ── Main button ──────────────────────────────────────────────────
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isHolding ? sosColor.withValues(alpha: 0.8) : sosColor,
                  sosColor.withValues(alpha: 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: sosColor.withValues(alpha: 0.5),
                  blurRadius: isHolding ? 30 : 20,
                  spreadRadius: isHolding ? 6 : 2,
                ),
              ],
            ),
            child: isTriggering
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, size: 48, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'اضغط مطولاً',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'للنداء',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Hold progress painter ────────────────────────────────────────────────────

class _HoldProgressPainter extends CustomPainter {
  _HoldProgressPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HoldProgressPainter old) => old.progress != progress;
}

// ─── Severity chip ────────────────────────────────────────────────────────────

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.label,
    required this.severity,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final SosSeverity severity;
  final bool isSelected;
  final VoidCallback onTap;

  Color _chipColorFor(BuildContext context) => switch (severity) {
    SosSeverity.low => context.semantic.textMuted,
    SosSeverity.standard => context.colors.primary,
    SosSeverity.high => context.semantic.warning,
    SosSeverity.critical => context.semantic.sos,
  };

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColorFor(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? context.semantic.textOnPrimary : chipColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Community dropdown ───────────────────────────────────────────────────────

class _CommunityDropdown extends ConsumerWidget {
  const _CommunityDropdown({required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider).communities;

    return Container(
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: communities.any((c) => c.id == selectedId) ? selectedId : null,
          hint: Text(
            'اختر مجتمعاً',
            textDirection: TextDirection.rtl,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
          dropdownColor: context.semantic.surfaceElevated,
          items: communities.map((c) {
            return DropdownMenuItem(
              value: c.id,
              child: Text(
                c.title,
                textDirection: TextDirection.rtl,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Severity badge ───────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (severity.toLowerCase()) {
      'high' => ('عالي', const Color(0xFFF59E0B)),
      'critical' => ('حرج', const Color(0xFF7F1D1D)),
      _ => ('عادي', const Color(0xFF3B82F6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Elapsed timer text in AppBar ─────────────────────────────────────────────

class _ElapsedTimerText extends StatelessWidget {
  const _ElapsedTimerText({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final text =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Text(
      text,
      style: TextStyle(
        color: context.semantic.sos,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─── Mini FlutterMap ──────────────────────────────────────────────────────────

class _SosMap extends StatelessWidget {
  const _SosMap({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ain.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: _PulsingDot(color: context.semantic.sos),
            ),
          ],
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 1.0 + _ctrl.value * 0.6;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha: (1.0 - _ctrl.value) * 0.4,
                  ),
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Location update row ──────────────────────────────────────────────────────

class _LocationUpdateRow extends StatelessWidget {
  const _LocationUpdateRow({this.lastUpdated});

  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final label = lastUpdated == null
        ? 'لم يتم التحديث بعد'
        : 'آخر تحديث موقع: منذ ${_secondsAgo(lastUpdated!)} ثانية';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _secondsAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt).inSeconds;
    return diff.toString();
  }
}

// ─── SOS status card ──────────────────────────────────────────────────────────

class _SosStatusCard extends StatelessWidget {
  const _SosStatusCard({this.alert});

  final SosAlertModel? alert;

  @override
  Widget build(BuildContext context) {
    final sosColor = context.semantic.sos;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.semantic.sosContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: sosColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.wifi_rounded, color: sosColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الحالة في الوقت الفعلي',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يتم مراقبة النداء عبر SignalR',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _accentEmerald,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AffectedCommunitiesLabel extends StatelessWidget {
  const _AffectedCommunitiesLabel({required this.alert});

  final SosAlertModel alert;

  @override
  Widget build(BuildContext context) {
    if (alert.allAffectedCommunityIds.length <= 1) {
      return const SizedBox.shrink();
    }

    final count = alert.allAffectedCommunityIds.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        'تم تنبيه $count مجتمعات',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
