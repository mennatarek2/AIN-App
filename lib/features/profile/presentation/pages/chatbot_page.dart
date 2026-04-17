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
    final assistantBubbleColor = isDark
        ? const Color(0xFFCDE6F8)
        : const Color(0xFFC6DEEF);
    final assistantTextColor = isDark
        ? const Color(0xFF060C3A)
        : AppColors.textPrimaryLight;
    final userBubbleColor = isDark
        ? const Color(0xFF0099FF)
        : AppColors.primary;
    final inputBackground = isDark
        ? const Color(0xFF121A5C)
        : AppColors.primarySoft;
    final inputTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

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
                  const Spacer(flex: 4),
                  _AssistantMessage(
                    bubbleColor: assistantBubbleColor,
                    textColor: assistantTextColor,
                    text:
                        'أهلاً بك، أنا هنا لمساعدتك في الإبلاغ\nآمناً. كيف يمكنني مساعدتك ؟',
                  ),
                  const SizedBox(height: 22),
                  _UserMessage(
                    text: 'كيفية تقديم بلّغ ؟',
                    bubbleColor: userBubbleColor,
                  ),
                  const SizedBox(height: 18),
                  _AssistantMessage(
                    large: true,
                    bubbleColor: assistantBubbleColor,
                    textColor: assistantTextColor,
                    text:
                        'لتقديم البلاغ اتبع الخطوات التالية:\nاضغط على زر إضافة بلاغ من الصفحة الرئيسية.\nاختر نوع البلاغ ثم فئة البلاغ المناسبة.\nأدخل عنوان البلاغ ثم اكتب وصف البلاغ.\nارفع صورة توضح البلاغ.\nحدد موقع البلاغ على الخريطة.\nاضغط على إرسال البلاغ.',
                  ),
                  const SizedBox(height: 22),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _messageController.clear();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
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
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 36 * 0.525,
                              fontWeight: FontWeight.w400,
                              color: inputTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'مراسلة...',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: TextStyle(
                                fontSize: 36 * 0.525,
                                fontWeight: FontWeight.w400,
                                color: inputTextColor.withValues(alpha: 0.8),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
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

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.text,
    required this.bubbleColor,
    required this.textColor,
    this.large = false,
  });

  final String text;
  final Color bubbleColor;
  final Color textColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: large ? 335 : 275),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: large ? 16 : 11,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(20),
                bottomRight: Radius.circular(large ? 30 : 22),
              ),
            ),
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                height: large ? 1.65 : 1.45,
                fontSize: 36 * 0.525,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Image.asset(
          'assets/images/assestant_chatbot.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text, required this.bubbleColor});

  final String text;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/user_chatbot.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),

            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 36 * 0.525,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
