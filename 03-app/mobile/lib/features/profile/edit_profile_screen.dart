import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/r_text_field.dart';
import '../auth/auth_controller.dart';
import '../auth/screens/auth_widgets.dart' show authError;
import 'profile_page.dart';
import 'wilayas.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _originalEmail = '';
  String? _wilaya;
  int? _childrenCount;
  bool _loading = false;
  ApiError? _error;

  bool get _emailChanged => _email.text.trim().toLowerCase() != _originalEmail;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
    _originalEmail = _email.text.trim().toLowerCase();
    _phone.text = user?.phone ?? '';
    _wilaya = user?.wilaya;
    _childrenCount = user?.childrenCount;
    _email.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    if (!_emailChanged) _password.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _email.removeListener(_onEmailChanged);
    for (final controller in [_name, _email, _phone, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final phone = _phone.text.replaceAll(RegExp(r'[\s-]+'), '');
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim().toLowerCase(),
            phone: phone.isEmpty ? null : phone,
            wilaya: _wilaya,
            childrenCount: _childrenCount,
            currentPassword: _emailChanged ? _password.text : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بيانات الحساب بنجاح.')),
      );
      context.canPop() ? context.pop() : context.go('/profile');
    } catch (error) {
      if (mounted) setState(() => _error = authError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _errors(String name) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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

  Widget _field(
    String name,
    String label,
    TextEditingController controller, {
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    bool obscure = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RTextField(
        key: ValueKey(name),
        label: label,
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscure: obscure,
      ),
      _errors(name),
    ],
  );

  Future<void> _pickWilaya() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WilayaPicker(selected: _wilaya),
    );
    if (!mounted || result == null) return;
    setState(() => _wilaya = result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'تعديل بيانات الحساب',
    child: AbsorbPointer(
      absorbing: _loading,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              'name',
              'الاسم',
              _name,
              validator: (value) {
                final length = value?.trim().characters.length ?? 0;
                return length < 2 || length > 80
                    ? 'الاسم من حرفين إلى 80 حرفًا.'
                    : null;
              },
            ),
            _field(
              'email',
              'البريد الإلكتروني',
              _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value == null ||
                      value.trim().length > 190 ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value.trim())
                  ? 'أدخل بريدًا إلكترونيًا صحيحًا.'
                  : null,
            ),
            if (_emailChanged)
              _field(
                'current_password',
                'كلمة المرور الحالية',
                _password,
                obscure: true,
                validator: (value) => value == null || value.isEmpty
                    ? 'كلمة المرور الحالية مطلوبة.'
                    : null,
              ),
            _field(
              'phone',
              'رقم الهاتف',
              _phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final phone = (value ?? '').replaceAll(RegExp(r'[\s-]+'), '');
                return phone.isEmpty ||
                        RegExp(r'^(?:\+213|0)[0-9]{9}$').hasMatch(phone)
                    ? null
                    : 'أدخل رقم هاتف جزائري صحيحًا.';
              },
            ),
            RCard(
              child: ListTile(
                key: const ValueKey('wilaya'),
                contentPadding: EdgeInsets.zero,
                title: const Text('الولاية'),
                subtitle: Text(_wilaya ?? 'غير محدد'),
                trailing: const Icon(Icons.expand_more),
                onTap: _pickWilaya,
              ),
            ),
            _errors('wilaya'),
            const SizedBox(height: RSpace.s4),
            RCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'عدد الأطفال',
                    style: RType.label.copyWith(color: context.c.textPrimary),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'تقليل عدد الأطفال',
                        onPressed: (_childrenCount ?? 0) > 0
                            ? () => setState(
                                () => _childrenCount = _childrenCount! - 1,
                              )
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Text(
                          _childrenCount?.toString() ?? 'غير محدد',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'زيادة عدد الأطفال',
                        onPressed: (_childrenCount ?? 0) < 20
                            ? () => setState(
                                () =>
                                    _childrenCount = (_childrenCount ?? 0) + 1,
                              )
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_childrenCount == null)
                    TextButton(
                      onPressed: () => setState(() => _childrenCount = 0),
                      child: const Text('لا يوجد أطفال'),
                    ),
                  if (_childrenCount != null)
                    TextButton(
                      onPressed: () => setState(() => _childrenCount = null),
                      child: const Text('إلغاء التحديد'),
                    ),
                ],
              ),
            ),
            _errors('children_count'),
            if (_error != null && _error!.fields.isEmpty)
              Text(
                _error!.message,
                style: RType.body.copyWith(color: context.c.feedbackErrorText),
              ),
            const SizedBox(height: RSpace.s4),
            RButton(
              label: 'حفظ التعديلات',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WilayaPicker extends StatefulWidget {
  const _WilayaPicker({this.selected});
  final String? selected;
  @override
  State<_WilayaPicker> createState() => _WilayaPickerState();
}

class _WilayaPickerState extends State<_WilayaPicker> {
  String _query = '';
  // Let searches without hamza match the displayed official Arabic names.
  String _normalize(String value) => value.replaceAll(RegExp('[أإآ]'), 'ا');
  @override
  Widget build(BuildContext context) {
    final results = wilayas.where(
      (w) => _normalize(w.label).contains(_normalize(_query)),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            RSpace.s4,
            RSpace.s4,
            RSpace.s4,
            MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: Column(
              children: [
                Text(
                  'اختر الولاية',
                  style: RType.heading3.copyWith(color: context.c.textPrimary),
                ),
                TextField(
                  key: const ValueKey('wilaya_search'),
                  decoration: const InputDecoration(
                    labelText: 'ابحث بالاسم أو الرقم',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                ListTile(
                  title: const Text('غير محدد'),
                  onTap: () => Navigator.of(context).pop(''),
                ),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('لا توجد نتائج'))
                      : ListView(
                          children: [
                            for (final wilaya in results)
                              ListTile(
                                title: Text(wilaya.label),
                                selected: wilaya.name == widget.selected,
                                onTap: () =>
                                    Navigator.of(context).pop(wilaya.name),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
