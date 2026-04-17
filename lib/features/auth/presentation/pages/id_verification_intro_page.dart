import 'package:flutter/material.dart';

import '../../../../config/routes/app_routes.dart';

class IdVerificationIntroPage extends StatelessWidget {
  const IdVerificationIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 132),
                Text(
                  'التحقق من الهوية',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'لإكمال عملية التسجيل الخاصة بك، ستحتاج إلى:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 17,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 48),
                _StepRow(
                  number: '1',
                  title: 'تصوير بطاقة الرقم القومي',
                  description: 'قم بتصوير الوجهين الأمامي والخلفي للبطاقة.',
                  textColor: colorScheme.onBackground,
                  badgeColor: colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                _StepRow(
                  number: '2',
                  title: 'التقاط صورة شخصية',
                  description: 'يُرجى التأكد من أن تكون الصورة واضحة و مناسبة',
                  textColor: colorScheme.onBackground,
                  badgeColor: colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                _StepRow(
                  number: '3',
                  title: 'تأكيد المعلومات الأساسية',
                  description:
                      'سيتم المراجعة والتأكد من صحة المعلومات التي أدخلتها',
                  textColor: colorScheme.onBackground,
                  badgeColor: colorScheme.secondary,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: SizedBox(
                    height: 52,
                    width: 300,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.idVerification);
                          },
                          child: const Center(
                            child: Text(
                              'المتابعة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 21,
                              ),
                            ),
                          ),
                        ),
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
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.description,
    required this.textColor,
    required this.badgeColor,
  });

  final String number;
  final String title;
  final String description;
  final Color textColor;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 21,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 17, height: 1.4, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
