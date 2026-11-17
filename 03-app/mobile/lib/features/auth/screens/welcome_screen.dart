import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.g.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/r_button.dart';
import '../../../core/widgets/watermark.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.c;
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [colors.copyWith(surfacePage: colors.surfaceBrandSoft)],
      ),
      child: AppScaffold(
        showWatermark: false,
        body: LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                end: -RSpace.s14,
                width:
                    constraints.maxWidth + RSpace.s24 + RSpace.s24 + RSpace.s4,
                top: -(RSpace.s16 + RSpace.s1_5),
                bottom: RSpace.s0,
                child: const Watermark(),
              ),
              PositionedDirectional(
                start: -RSpace.s6,
                end: -RSpace.s6,
                bottom: RSpace.s10,
                height: RSpace.s24 + RSpace.s24,
                child: RotatedBox(quarterTurns: 2, child: const Watermark()),
              ),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: RSpace.s12),
                        Center(
                          child: Image.asset(
                            'assets/images/riayati-symbol.png',
                            width: RSpace.s24 + RSpace.s12 + RSpace.s1,
                            semanticLabel: 'شعار رعايتي',
                          ),
                        ),
                        const SizedBox(height: RSpace.s5),
                        Text(
                          'رعايتي',
                          textAlign: TextAlign.center,
                          style: RType.display.copyWith(
                            fontSize: RSpace.s12,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: RSpace.s1),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: RSpace.s5,
                          ),
                          child: Text(
                            'مساحة آمنة لحماية الأطفال ومعرفة الحقوق في إطار الحضانة.',
                            textAlign: TextAlign.center,
                            style: RType.bodyLg.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: RSpace.s6),
                        const Spacer(),
                        RButton(
                          label: 'إنشاء حساب',
                          onPressed: () => context.go('/register'),
                        ),
                        const SizedBox(height: RSpace.s3),
                        RButton(
                          label: 'تسجيل الدخول',
                          kind: RButtonKind.secondary,
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(height: RSpace.s4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: RSpace.s5,
                              color: colors.primary,
                            ),
                            const SizedBox(width: RSpace.s2),
                            Expanded(
                              child: Text(
                                'بياناتك خاصة، ولا يطّلع الطرف الآخر إلا على التقويم المشترك.',
                                style: RType.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RSpace.s5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
