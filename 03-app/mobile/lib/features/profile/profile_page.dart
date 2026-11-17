import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';

/// Shared RTL page frame for the profile's pushed routes.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/profile'),
              icon: const BackButtonIcon(),
            ),
            Expanded(
              child: Text(
                title,
                style: RType.heading3.copyWith(color: context.c.textPrimary),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.only(
              top: RSpace.s4,
              bottom: RSpace.s6,
            ),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class ProfileLegalPage extends StatelessWidget {
  const ProfileLegalPage({
    super.key,
    required this.title,
    required this.sections,
  });
  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نسخة مبدئية، سيُستبدل النص النهائي قبل الإطلاق',
          style: RType.bodyLegal.copyWith(color: context.c.textPrimary),
        ),
        for (final (heading, body) in sections) ...[
          const SizedBox(height: RSpace.s6),
          Text(
            heading,
            style: RType.heading3.copyWith(color: context.c.textPrimary),
          ),
          const SizedBox(height: RSpace.s2),
          Text(
            body,
            style: RType.bodyLegal.copyWith(color: context.c.textPrimary),
          ),
        ],
      ],
    ),
  );
}
