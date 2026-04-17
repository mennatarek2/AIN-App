import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class PointsPage extends ConsumerWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final primaryTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final cardTextColor = isDark
        ? const Color(0xFF060C3A)
        : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _PointsHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFF3F6F9) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFF3F6F9)
                        : const Color(0x66415789),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                          BoxShadow(
                            color: Color(0x4D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/points_level.png',
                      width: 186,
                      height: 186,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: profile.levelDotColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.level,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: cardTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'متبقي ${profile.pointsToNextLevel} نقطة لتصل مستوى ${profile.level} !\nاستمر في المشاركة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36 * 0.525,
                        fontWeight: FontWeight.w500,
                        color: cardTextColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        minHeight: 16,
                        value: (profile.points % 100) / 100,
                        backgroundColor: isDark
                            ? const Color(0xFFD9D9D9)
                            : const Color(0xFFE0E2E6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0F9DFA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المستويات المحققة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 40 * 0.525,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _LevelItem(
                      label: 'مستخدم جديد',
                      dotColor: const Color(0xFF697184),
                      achieved: profile.points >= 0,
                    ),
                    const SizedBox(height: 10),
                    _LevelItem(
                      label: 'مساهم',
                      dotColor: const Color(0xFF498EF4),
                      achieved: profile.points >= 100,
                    ),
                    const SizedBox(height: 10),
                    _LevelItem(
                      label: 'موثق',
                      dotColor: const Color(0xFF14B57A),
                      achieved: profile.points >= 200,
                    ),
                    const SizedBox(height: 10),
                    _LevelItem(
                      label: 'متميز',
                      dotColor: const Color(0xFFF59E0B),
                      achieved: profile.points >= 300,
                    ),
                    const SizedBox(height: 24),
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

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(Icons.arrow_forward_ios, color: titleColor, size: 24),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 0.32),
              child: Text(
                'النقاط',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelItem extends StatelessWidget {
  const _LevelItem({
    required this.label,
    required this.dotColor,
    required this.achieved,
  });

  final String label;
  final Color dotColor;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelLabelColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final rowBackground = achieved
        ? (isDark ? const Color(0xFF243C6B) : const Color(0xFFD0E6F5))
        : (isDark ? const Color(0xFF464B73) : const Color(0xFFD2D5DD));

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Icon(
            achieved
                ? Icons.check_circle_outline_rounded
                : Icons.lock_outline_rounded,
            size: 30,
            color: const Color(0xFF0F9DFA),
          ),
          const Spacer(),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.circle, size: 16, color: dotColor),
              const SizedBox(width: 10),
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 36 * 0.525,
                  fontWeight: FontWeight.w500,
                  color: levelLabelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
