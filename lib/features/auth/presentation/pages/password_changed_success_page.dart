import 'package:flutter/material.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/widgets/checkmark_success_animation.dart';

class PasswordChangedSuccessPage extends StatelessWidget {
  const PasswordChangedSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                const CheckmarkSuccessAnimation(),
                const SizedBox(height: 52),
                Text(
                  'تم تغيير كلمة المرور بنجاح',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة',
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
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.login);
                        },
                        child: const Center(
                          child: Text(
                            'تسجيل الدخول',
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
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
