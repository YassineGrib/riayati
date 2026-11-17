import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/widgets/r_button.dart';
import '../../../core/widgets/r_text_field.dart';
import '../auth_repository.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  ApiError? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    backRoute: '/login',
    footer: _sent ? null : const AuthLink('العودة إلى تسجيل الدخول', '/login'),
    child: _sent
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: RSpace.s8),
              Center(
                child: Container(
                  width: RSpace.s20,
                  height: RSpace.s20,
                  decoration: BoxDecoration(
                    color: context.c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: RSpace.s10,
                    color: context.c.primary,
                  ),
                ),
              ),
              const SizedBox(height: RSpace.s6),
              const AuthTitle(
                'تحقق من بريدك',
                centered: true,
                lead: 'إذا كان البريد مسجّلًا لدينا فقد أرسلنا إليه رابط الاستعادة.',
              ),
              RButton(
                label: 'العودة إلى تسجيل الدخول',
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: RSpace.s2),
              TextButton(
                onPressed: () => setState(() => _sent = false),
                child: Text(
                  'إرسال الرابط',
                  style: RType.label.copyWith(color: context.c.textLink),
                ),
              ),
            ],
          )
        : Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthTitle(
                  'استعادة كلمة المرور',
                  lead: 'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لتعيين كلمة مرور جديدة.',
                ),
                RTextField(
                  label: 'البريد الإلكتروني',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: RSpace.s2),
                RButton(
                  label: 'إرسال الرابط',
                  onPressed: _submit,
                  loading: _loading,
                ),
                AuthError(_error),
              ],
            ),
          ),
  );
}
