import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'r_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StateContent(
    icon: Icons.cloud_off_outlined,
    title: 'تعذر تحميل البيانات',
    body: message,
    error: true,
    action: onRetry == null
        ? null
        : RButton(label: 'إعادة المحاولة', onPressed: onRetry),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: 'جارٍ التحميل',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: context.c.primary,
            strokeWidth: RBorderWidth.medium,
          ),
          const SizedBox(height: RSpace.s4),
          Text(
            'جارٍ التحميل',
            style: RType.caption.copyWith(color: context.c.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.body, this.action});

  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StateContent(
    icon: Icons.description_outlined,
    title: title,
    body: body,
    action: action,
  );
}

class _StateContent extends StatelessWidget {
  const _StateContent({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: RSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: RSpace.s20,
              height: RSpace.s20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: error ? c.feedbackErrorBg : c.accentSoft,
              ),
              child: Icon(
                icon,
                size: RSpace.s10,
                color: error ? c.feedbackErrorIcon : c.primary,
              ),
            ),
            const SizedBox(height: RSpace.s6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: RType.heading2.copyWith(
                fontFamily: RType.display.fontFamily,
                color: c.textPrimary,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: RSpace.s3),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: RType.body.copyWith(color: c.textSecondary),
              ),
            ],
            if (action != null) ...[const SizedBox(height: RSpace.s7), action!],
          ],
        ),
      ),
    );
  }
}
