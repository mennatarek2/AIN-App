import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/theme_extensions.dart';

/// Numeric OTP input with guaranteed visible digits in light/dark themes.
class AppOtpInput extends StatefulWidget {
  const AppOtpInput({
    super.key,
    required this.length,
    required this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalizeDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternArabicIndic = [
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹',
    ];

    var normalized = input;
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabicIndic[i], i.toString());
      normalized = normalized.replaceAll(easternArabicIndic[i], i.toString());
    }
    return normalized.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final digitColor = context.colors.onSurface;
    final cursorColor = context.colors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const maxFieldWidth = 48.0;
        const minFieldWidth = 36.0;
        const fieldHeight = 56.0;

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final totalSpacing = spacing * (widget.length - 1);
        final fieldWidth = ((availableWidth - totalSpacing) / widget.length)
            .clamp(minFieldWidth, maxFieldWidth)
            .toDouble();

        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (index) {
                  final char = index < code.length ? code[index] : null;
                  final isFilled = char != null;
                  final isFocused =
                      widget.enabled &&
                      _focusNode.hasFocus &&
                      index == code.length.clamp(0, widget.length - 1);

                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == widget.length - 1 ? 0 : spacing,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: fieldWidth,
                      height: fieldHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? context.colors.primary.withValues(alpha: 0.08)
                            : context.semantic.surfaceInput,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: isFocused
                              ? cursorColor
                              : isFilled
                              ? context.colors.primary
                              : context.semantic.borderSubtle,
                          width: isFocused ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        char ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: digitColor,
                          height: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Opacity(
              opacity: 0.01,
              child: SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: widget.length,
                  showCursor: true,
                  cursorColor: cursorColor,
                  cursorWidth: 2,
                  style: TextStyle(
                    color: digitColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final normalized = _normalizeDigits(value);
                    if (normalized != value) {
                      _controller.value = TextEditingValue(
                        text: normalized,
                        selection: TextSelection.collapsed(
                          offset: normalized.length,
                        ),
                      );
                    }
                    setState(() {});
                    widget.onChanged(normalized);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Alphanumeric invite-code display (6 chars) with responsive boxes.
class AppInviteCodeInput extends StatelessWidget {
  const AppInviteCodeInput({
    super.key,
    required this.code,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    this.enabled = true,
    this.length = 6,
  });

  final String code;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int length;

  @override
  Widget build(BuildContext context) {
    final digitColor = context.colors.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        const maxBoxWidth = 44.0;
        const minBoxWidth = 28.0;
        const boxHeight = 52.0;

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 80;
        final totalSpacing = spacing * (length - 1);
        final rawWidth = (availableWidth - totalSpacing) / length;
        final boxWidth = rawWidth.clamp(minBoxWidth, maxBoxWidth).toDouble();
        final needsScale = rawWidth < minBoxWidth;

        Widget boxesRow = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(length, (index) {
            final char = index < code.length ? code[index] : null;
            final isFilled = char != null;

            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == length - 1 ? 0 : spacing,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: boxWidth,
                height: boxHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFilled
                      ? context.colors.primary.withValues(alpha: 0.1)
                      : context.semantic.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: hasError
                        ? context.semantic.error
                        : isFilled
                        ? context.colors.primary
                        : context.semantic.borderSubtle,
                    width: isFilled ? 2 : 1,
                  ),
                ),
                child: Text(
                  char ?? '•',
                  style: TextStyle(
                    fontSize: boxWidth < 34 ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    color: isFilled ? digitColor : context.semantic.textMuted,
                  ),
                ),
              ),
            );
          }),
        );

        if (needsScale) {
          boxesRow = FittedBox(fit: BoxFit.scaleDown, child: boxesRow);
        }

        return SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: enabled ? () => focusNode.requestFocus() : null,
                child: boxesRow,
              ),
              Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  maxLength: length,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  style: TextStyle(
                    color: digitColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  cursorColor: context.colors.primary,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
