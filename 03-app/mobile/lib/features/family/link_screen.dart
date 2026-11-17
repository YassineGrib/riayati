import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../auth/screens/auth_widgets.dart' show AuthError, authError;
import 'family_repository.dart';

class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({super.key});

  @override
  ConsumerState<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends ConsumerState<LinkScreen> {
  final _code = TextEditingController();
  late Future<InviteCode> _invite;
  bool _linking = false;
  bool _signingOut = false;
  ApiError? _linkError;
  ApiError? _signOutError;

  @override
  void initState() {
    super.initState();
    // Creating an invite replaces the previous code on the server. Keep this
    // operation scoped to this screen, without automatic provider retries.
    _invite = ref.read(familyRepositoryProvider).invite();
  }

  void _retryInvite() {
    setState(() {
      _invite = ref.read(familyRepositoryProvider).invite();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_linking || _signingOut || _code.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _linking = true;
      _linkError = null;
    });
    try {
      await ref.read(familyRepositoryProvider).link(_code.text);
    } catch (error) {
      if (mounted) setState(() => _linkError = authError(error));
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut || _linking) return;
    setState(() {
      _signingOut = true;
      _signOutError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (error) {
      if (mounted) setState(() => _signOutError = authError(error));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _copy(String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم نسخ الرمز')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر نسخ الرمز. حاول مجددًا.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: RSpace.s14),
                  const SizedBox(height: RSpace.s2),
                  Text(
                    'ربط حساب الطرف الآخر',
                    style: RType.heading1.copyWith(
                      color: context.c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: RSpace.s2),
                  Text(
                    'لتشاركا تقويم الزيارات، اربطا حسابيكما برمز دعوة. لن يطّلع الطرف الآخر إلا على التقويم المشترك.',
                    style: RType.body.copyWith(color: context.c.textSecondary),
                  ),
                  const SizedBox(height: RSpace.s4),
                  RCard(
                    child: FutureBuilder<InviteCode>(
                      future: _invite,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const LoadingView();
                        }
                        if (snapshot.hasError) {
                          return ErrorView(
                            message: authError(snapshot.error!).message,
                            onRetry: _retryInvite,
                          );
                        }
                        final value = snapshot.requireData;
                        return _InviteCard(
                          invite: value,
                          onCopy: () => _copy(value.code),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: context.c.border,
                            thickness: RBorderWidth.thin,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: RSpace.s3,
                          ),
                          child: Text(
                            'أو',
                            style: RType.caption.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: context.c.border,
                            thickness: RBorderWidth.thin,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'لديّ رمز من الطرف الآخر',
                    style: RType.label.copyWith(color: context.c.textPrimary),
                  ),
                  const SizedBox(height: RSpace.s1_5),
                  // RTextField has no direction, alignment or hint overrides.
                  // This code-only control preserves the board's LTR grouping.
                  TextFormField(
                    controller: _code,
                    onChanged: (_) => setState(() => _linkError = null),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    onFieldSubmitted: (_) => _link(),
                    style: RType.heading3.copyWith(
                      fontWeight: RType.body.fontWeight,
                      color: context.c.textPrimary,
                    ),
                    cursorColor: context.c.primary,
                    decoration: InputDecoration(
                      hintText: 'XXX-XXX',
                      hintStyle: RType.heading3.copyWith(
                        fontWeight: RType.body.fontWeight,
                        color: context.c.textTertiary,
                      ),
                      filled: true,
                      fillColor: context.c.surface,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: RSpace.s4,
                        vertical: RSpace.s3,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RRadius.xl),
                        borderSide: BorderSide(
                          color: context.c.borderStrong,
                          width: RBorderWidth.thin,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RRadius.xl),
                        borderSide: BorderSide(
                          color: context.c.borderFocus,
                          width: RBorderWidth.medium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: RSpace.s3),
                  AuthError(_linkError),
                  if (_linkError != null) const SizedBox(height: RSpace.s3),
                  RButton(
                    label: 'ربط الحساب',
                    loading: _linking,
                    onPressed: _signingOut || _code.text.trim().isEmpty
                        ? null
                        : _link,
                  ),
                  const SizedBox(height: RSpace.s6),
                  const Spacer(),
                  RButton(
                    label: 'تسجيل الخروج',
                    kind: RButtonKind.text,
                    loading: _signingOut,
                    onPressed: _linking ? null : _signOut,
                  ),
                  AuthError(_signOutError),
                  const SizedBox(height: RSpace.s2),
                  Text(
                    'لن يعمل التقويم المشترك قبل الربط.',
                    textAlign: TextAlign.center,
                    style: RType.caption.copyWith(
                      color: context.c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: RSpace.s4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.onCopy});

  final InviteCode invite;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            'رمزك',
            style: RType.label.copyWith(color: context.c.textPrimary),
          ),
          const SizedBox(width: RSpace.s3),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: RSpace.s3,
                  vertical: RSpace.s1,
                ),
                decoration: BoxDecoration(
                  color: context.c.surfaceSunken,
                  borderRadius: BorderRadius.circular(RRadius.full),
                ),
                child: Text(
                  'ينتهي في ${DateFormat('yyyy/MM/dd HH:mm', 'en').format(invite.expiresAt.toLocal())}',
                  style: RType.caption.copyWith(color: context.c.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: RSpace.s3),
      Container(
        constraints: const BoxConstraints(minHeight: RSpace.s16 + RSpace.s2),
        padding: const EdgeInsetsDirectional.all(RSpace.s2),
        decoration: BoxDecoration(
          color: context.c.surfaceBrandSoft,
          borderRadius: BorderRadius.circular(RRadius.xl),
        ),
        child: Text(
          invite.code,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: RType.display.copyWith(
            fontFamily: RType.body.fontFamily,
            color: context.c.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: RSpace.s3),
      RButton(
        label: 'نسخ',
        icon: Icons.copy_outlined,
        kind: RButtonKind.secondary,
        onPressed: onCopy,
      ),
    ],
  );
}
