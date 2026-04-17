import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import 'edit_password_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkModeOn =
        ref.watch(appSettingsProvider).themeMode == ThemeMode.dark;
    final textColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0xFF060C3A);
    final dividerColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0x33415789);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060C3A)
          : Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _SettingsHeader(onBack: () => Navigator.of(context).pop()),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditPasswordPage(),
                        ),
                      );
                    },
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Icon(Icons.chevron_right, color: textColor, size: 30),
                        const Spacer(),
                        Text(
                          'تغيير كلمة المرور',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 40 * 0.525,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      _OffStyleSwitch(
                        value: isDarkModeOn,
                        onChanged: (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setDarkModeEnabled(value);
                        },
                      ),
                      const Spacer(),
                      Text(
                        'الوضع الداكن',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 40 * 0.525,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ],
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBackground = isDark
        ? const Color(0xFF121A5C)
        : Theme.of(context).colorScheme.primary;
    final headerTextColor = isDark ? const Color(0xFFF3F6F9) : Colors.white;

    return Container(
      width: double.infinity,
      height: 100,
      color: headerBackground,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(
                Icons.arrow_forward_ios,
                color: headerTextColor,
                size: 24,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                'الإعدادات',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: headerTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffStyleSwitch extends StatelessWidget {
  const _OffStyleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 94,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0F9DFA) : const Color(0xFF121A5C),
          border: Border.all(color: const Color(0xFFF3F6F9), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Align(
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F6F9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
