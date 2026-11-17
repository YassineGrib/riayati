import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/widgets/r_button.dart';
import '../../../core/widgets/r_text_field.dart';
import '../auth_controller.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _role;
  bool _terms = false;
  bool _loading = false;
  ApiError? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || _role == null || !_terms || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role!,
            terms: _terms,
          );
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _roleChoice(String role, String label) {
    final selected = _role == role;
    return Expanded(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        child: OutlinedButton(
          onPressed: _loading ? null : () => setState(() => _role = role),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(RSpace.s12, RSpace.s14),
            backgroundColor: selected
                ? context.c.interactiveSelectedBg
                : context.c.surface,
            foregroundColor: context.c.textPrimary,
            side: BorderSide(
              color: selected ? context.c.borderFocus : context.c.borderStrong,
              width: selected ? RBorderWidth.medium : RBorderWidth.thin,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RRadius.xl),
            ),
            textStyle: RType.body,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: RSpace.s5),
                const SizedBox(width: RSpace.s2),
              ],
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    footer: const AuthFooter('لديك حساب؟', 'تسجيل الدخول', '/login'),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTitle('إنشاء حساب'),
          RTextField(
            label: 'الاسم الكامل',
            controller: _name,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'الاسم الكامل مطلوب.'
                : null,
          ),
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
            helper: '8 أحرف على الأقل.',
            validator: (value) => value == null || value.isEmpty
                ? 'كلمة المرور مطلوبة.'
                : value.length < 8
                ? '8 أحرف على الأقل.'
                : null,
          ),
          Text(
            'أنا',
            style: RType.label.copyWith(color: context.c.textPrimary),
          ),
          const SizedBox(height: RSpace.s1_5),
          Row(
            children: [
              _roleChoice('father', 'أب'),
              const SizedBox(width: RSpace.s3),
              _roleChoice('mother', 'أم'),
            ],
          ),
          const SizedBox(height: RSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _terms,
                semanticLabel: 'أوافق على شروط الاستخدام وسياسة الخصوصية.',
                activeColor: context.c.primary,
                checkColor: context.c.onPrimary,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _terms = value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: RSpace.s3),
                  child: Text(
                    'أوافق على شروط الاستخدام وسياسة الخصوصية.',
                    style: RType.caption.copyWith(color: context.c.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s3),
          RButton(
            label: 'إنشاء الحساب',
            loading: _loading,
            onPressed: _role != null && _terms ? _submit : null,
          ),
          AuthError(_error),
        ],
      ),
    ),
  );
}
