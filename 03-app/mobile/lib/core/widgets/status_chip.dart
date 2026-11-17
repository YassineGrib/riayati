import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

enum StatusTone { neutral, info, success, warning, error }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (c.surfaceSunken, c.textPrimary),
      StatusTone.info => (c.feedbackInfoBg, c.feedbackInfoText),
      StatusTone.success => (c.feedbackSuccessBg, c.feedbackSuccessText),
      StatusTone.warning => (c.feedbackWarningBg, c.feedbackWarningText),
      StatusTone.error => (c.feedbackErrorBg, c.feedbackErrorText),
    };
    // Informational, not interactive: the visual badge is 28 dp high.
    return Container(
      constraints: const BoxConstraints(minHeight: RSpace.s7),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: RSpace.s3,
        vertical: RSpace.s0_5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RRadius.full),
      ),
      child: Text(label, style: RType.label.copyWith(color: foreground)),
    );
  }
}
