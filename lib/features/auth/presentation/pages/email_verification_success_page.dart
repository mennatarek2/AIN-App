import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmailVerificationSuccessArgs {
  final String nextRoute;

  const EmailVerificationSuccessArgs({required this.nextRoute});
}

class EmailVerificationSuccessPage extends StatelessWidget {
  const EmailVerificationSuccessPage({super.key});

  static const String _checkmarkAnimationAssetPath =
      'assets/animations/report_success.lottie';

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments
            as EmailVerificationSuccessArgs?;
    final nextRoute = args?.nextRoute;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 140),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    _checkmarkAnimationAssetPath,
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 52),
                Text(
                  'تم التحقق من البريد الإلكتروني بنجاح',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'يمكنك الآن استكمال إنشاء الحساب',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 17,
                    color: colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  height: 52,
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
                          if (nextRoute != null && nextRoute.isNotEmpty) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(nextRoute);
                          }
                        },
                        child: Center(
                          child: Text(
                            'استمرار',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 21,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
