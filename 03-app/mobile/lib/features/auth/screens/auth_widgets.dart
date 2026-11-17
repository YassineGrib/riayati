import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Keeps the footer at the bottom, while allowing forms and large Arabic type
/// to scroll when the keyboard or a smaller viewport reduces the available space.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.child,
    this.footer,
    this.backRoute = '/welcome',
  });

  final Widget child;
  final Widget? footer;
  final String backRoute;

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: RSpace.s14,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: 'رجوع',
                      onPressed: () => context.go(backRoute),
                      icon: const BackButtonIcon(),
                    ),
                  ),
                ),
                const SizedBox(height: RSpace.s2),
                child,
                const Spacer(),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: RSpace.s2,
                      bottom: RSpace.s4,
                    ),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthTitle extends StatelessWidget {
  const AuthTitle(this.title, {super.key, this.lead, this.centered = false});
  final String title;
  final String? lead;
  final bool centered;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: RType.heading1.copyWith(color: context.c.textPrimary),
      ),
      SizedBox(height: lead == null ? RSpace.s5 : RSpace.s2),
      if (lead != null) ...[
        Text(
          lead!,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: RType.body.copyWith(color: context.c.textSecondary),
        ),
        const SizedBox(height: RSpace.s6),
      ],
    ],
  );
}

class AuthLink extends StatelessWidget {
  const AuthLink(this.label, this.route, {super.key});
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => context.go(route),
    style: TextButton.styleFrom(
      foregroundColor: context.c.textLink,
      minimumSize: const Size(RSpace.s12, RSpace.s12),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s1),
      textStyle: RType.label.copyWith(decoration: TextDecoration.underline),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class AuthFooter extends StatelessWidget {
  const AuthFooter(this.prompt, this.label, this.route, {super.key});
  final String prompt;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        prompt,
        style: RType.caption.copyWith(color: context.c.textSecondary),
      ),
      AuthLink(label, route),
    ],
  );
}

class AuthError extends StatelessWidget {
  const AuthError(this.error, {super.key});
  final ApiError? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    // Preserve Laravel's field messages as well as the response summary.
    final messages = <String>{
      error!.message,
      ...error!.fields.values.expand((v) => v),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsetsDirectional.only(top: RSpace.s5),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: RSpace.s4,
          vertical: RSpace.s3,
        ),
        decoration: BoxDecoration(
          color: context.c.feedbackErrorBg,
          border: Border.all(
            color: context.c.feedbackErrorBorder,
            width: RBorderWidth.thin,
          ),
          borderRadius: BorderRadius.circular(RRadius.xl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: RSpace.s5,
              color: context.c.feedbackErrorIcon,
            ),
            const SizedBox(width: RSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final message in messages)
                    Text(
                      message,
                      style: RType.caption.copyWith(
                        color: context.c.feedbackErrorText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'البريد الإلكتروني مطلوب.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'أدخل بريدًا إلكترونيًا صالحًا.';
  }
  return null;
}

ApiError authError(Object error) => error is ApiError
    ? error
    : const ApiError(message: 'تعذر إتمام الطلب. حاول مجددًا.');
