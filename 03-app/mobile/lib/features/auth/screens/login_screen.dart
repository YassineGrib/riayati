import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/widgets/r_button.dart';
import '../../../core/widgets/r_text_field.dart';
import '../auth_controller.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  ApiError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: _email.text.trim(), password: _password.text);
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    footer: const AuthFooter('ليس لديك حساب؟', 'إنشاء حساب', '/register'),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTitle('مرحبًا بعودتك', lead: 'سجّل الدخول لمتابعة ملفك.'),
          RTextField(
            label: 'البريد الإلكتروني',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          RTextField(
            label: 'كلمة المرور',
            controller: _password,
            obscure: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'كلمة المرور مطلوبة.' : null,
          ),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: AuthLink('نسيت كلمة المرور؟', '/forgot'),
          ),
          const SizedBox(height: RSpace.s3),
          RButton(label: 'تسجيل الدخول', onPressed: _submit, loading: _loading),
          AuthError(_error),
        ],
      ),
    ),
  );
}
