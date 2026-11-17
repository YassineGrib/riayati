import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_text_field.dart';
import '../auth/auth_repository.dart';
import '../auth/screens/auth_widgets.dart' show authError;
import 'profile_page.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  ApiError? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
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
          .read(authRepositoryProvider)
          .changePassword(
            current: _current.text,
            next: _next.text,
            confirmation: _confirmation.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح.')),
      );
      context.canPop() ? context.pop() : context.go('/profile');
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String name,
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validator,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RTextField(
        label: label,
        controller: controller,
        obscure: true,
        validator: validator,
      ),
      for (final message in _error?.fields[name] ?? <String>[])
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: RSpace.s2),
          child: Text(
            message,
            style: RType.caption.copyWith(color: context.c.feedbackErrorText),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'تغيير كلمة المرور',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'current_password',
            'كلمة المرور الحالية',
            _current,
            (value) => value == null || value.isEmpty
                ? 'كلمة المرور الحالية مطلوبة.'
                : null,
          ),
          _field(
            'password',
            'كلمة المرور الجديدة',
            _next,
            (value) =>
                value == null || value.length < 8 ? '8 أحرف على الأقل.' : null,
          ),
          _field(
            'password_confirmation',
            'تأكيد كلمة المرور الجديدة',
            _confirmation,
            (value) => value == null || value.isEmpty || value != _next.text
                ? 'تأكيد كلمة المرور غير مطابق.'
                : null,
          ),
          if (_error != null && _error!.fields.isEmpty)
            Text(
              _error!.message,
              style: RType.body.copyWith(color: context.c.feedbackErrorText),
            ),
          const SizedBox(height: RSpace.s4),
          RButton(
            label: 'حفظ كلمة المرور',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );
}
