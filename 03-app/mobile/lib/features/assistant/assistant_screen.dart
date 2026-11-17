import 'package:flutter/material.dart';

import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/status_chip.dart';

/// Static preview: no auth, case data, API client or sending callback is used.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppScaffold(
      title: 'المساعد القانوني',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: RSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(RSpace.s4),
                    decoration: BoxDecoration(
                      color: c.surfaceBrandSoft,
                      border: Border.all(
                        color: c.border,
                        width: RBorderWidth.thin,
                      ),
                      borderRadius: BorderRadius.circular(RRadius.x2xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: RSpace.s10,
                              height: RSpace.s10,
                              decoration: BoxDecoration(
                                color: c.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: RSpace.s5,
                                color: c.primary,
                              ),
                            ),
                            const SizedBox(width: RSpace.s3),
                            Expanded(
                              child: Text(
                                'اسأل عن قانون الأسرة الجزائري',
                                style: RType.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RSpace.s2),
                        Text(
                          'أجيب من النصوص المعتمدة فقط، وأذكر المواد التي استندت إليها عند توفرها.',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: RSpace.s3),
                        const StatusChip(
                          label: 'قريبًا',
                          tone: StatusTone.neutral,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RSpace.s6),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: RSpace.s4,
                      vertical: RSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: c.feedbackInfoBg,
                      border: Border.all(
                        color: c.feedbackInfoBorder,
                        width: RBorderWidth.thin,
                      ),
                      borderRadius: BorderRadius.circular(RRadius.xl),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: RSpace.s5,
                          color: c.feedbackInfoIcon,
                        ),
                        const SizedBox(width: RSpace.s2),
                        Expanded(
                          child: Text(
                            'لا تكتب أسماء أو تفاصيل القضية. هذه معلومات عامة وليست استشارة قانونية.',
                            style: RType.caption.copyWith(
                              color: c.feedbackInfoText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RSpace.s8),
                  Text(
                    'جرّب أن تسأل',
                    style: RType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: RSpace.s2),
                  for (final question in _questions) ...[
                    Semantics(
                      button: true,
                      enabled: false,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: RSpace.s12,
                        ),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: RSpace.s4,
                          vertical: RSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: c.borderStrong,
                            width: RBorderWidth.thin,
                          ),
                          borderRadius: BorderRadius.circular(RRadius.xl),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question,
                                style: RType.body.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: RSpace.s2),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: RSpace.s4,
                              color: c.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: RSpace.s2),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: RSpace.s3,
              bottom: RSpace.s3,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(
                  color: c.borderStrong,
                  width: RBorderWidth.thin,
                ),
                borderRadius: BorderRadius.circular(RRadius.xl),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: false,
                      style: RType.body.copyWith(color: c.textDisabled),
                      decoration: InputDecoration(
                        hintText: 'اكتب سؤالك…',
                        hintStyle: RType.body.copyWith(color: c.textDisabled),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsetsDirectional.all(
                          RSpace.s4,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إرسال',
                    onPressed: null,
                    disabledColor: c.textDisabled,
                    icon: const Icon(Icons.send_outlined, size: RSpace.s6),
                  ),
                  const SizedBox(width: RSpace.s2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _questions = [
  'من الأحق بحضانة الطفل؟',
  'كيف تُنظَّم زيارة الطفل؟',
  'ما الذي تشمله نفقة الأولاد؟',
];
