import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final inputBackground = isDark
        ? const Color(0xFF121A5C)
        : AppColors.primarySoft;
    final inputTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _ChatbotHeader(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 64,
                    color: secondaryTextColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'المساعد الذكي غير متاح حالياً',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: inputTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم تفعيل هذه الميزة عند توفر واجهة برمجة التطبيقات',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      GestureDetector(
                        onTap: null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: inputBackground,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            enabled: false,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 36 * 0.525,
                              fontWeight: FontWeight.w400,
                              color: inputTextColor.withValues(alpha: 0.5),
                            ),
                            decoration: InputDecoration(
                              hintText: 'مراسلة...',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: TextStyle(
                                fontSize: 36 * 0.525,
                                fontWeight: FontWeight.w400,
                                color: inputTextColor.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatbotHeader extends StatelessWidget {
  const _ChatbotHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
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
              child: Icon(Icons.arrow_forward_ios, color: textColor, size: 24),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 0.32),
              child: Text(
                'المساعد الذكي',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
