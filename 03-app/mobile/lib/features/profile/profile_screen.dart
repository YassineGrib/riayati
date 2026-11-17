import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _confirmingSignOut = false;
  bool _signingOut = false;

  Future<void> _confirmSignOut() async {
    if (_confirmingSignOut || _signingOut) return;
    setState(() => _confirmingSignOut = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد الخروج'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _confirmingSignOut = false;
      _signingOut = confirmed == true;
    });
    if (confirmed != true) return;
    try {
      // Auth clears the local session even if the logout request fails.
      // The app's auth guard owns the return to the welcome route.
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إكمال تسجيل الخروج على الخادم.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final c = context.c;
    final partnerLabel = switch (user?.partnerRole) {
      'father' => 'مرتبط بالأب',
      'mother' => 'مرتبط بالأم',
      _ => 'مرتبط',
    };
    return AppScaffold(
      title: 'حسابي',
      body: user == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.only(
                top: RSpace.s4,
                bottom: RSpace.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: RSpace.s16 + RSpace.s2,
                          height: RSpace.s16 + RSpace.s2,
                          alignment: AlignmentDirectional.center,
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            user.name.trim().isEmpty
                                ? ''
                                : user.name.trim().characters.first,
                            style: RType.heading1.copyWith(color: c.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: RSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: RType.heading2.copyWith(
                                fontFamily: RType.display.fontFamily,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              user.email,
                              textDirection: TextDirection.ltr,
                              style: RType.caption.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: RSpace.s1),
                            StatusChip(
                              label: user.role == 'father' ? 'أب' : 'أم',
                              tone: StatusTone.neutral,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RSpace.s4),
                  RCard(
                    child: Row(
                      children: [
                        Icon(Icons.link, size: RSpace.s6, color: c.primary),
                        const SizedBox(width: RSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'حساب الطرف الآخر',
                                style: RType.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              Text(
                                user.linked
                                    ? 'يرى التقويم المشترك فقط.'
                                    : 'لم يتم الربط بعد.',
                                style: RType.caption.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                              if (user.linked) ...[
                                const SizedBox(height: RSpace.s1),
                                StatusChip(
                                  label: partnerLabel,
                                  tone: StatusTone.success,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RSpace.s4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border.all(
                        color: c.border,
                        width: RBorderWidth.thin,
                      ),
                      borderRadius: BorderRadius.circular(RRadius.x2xl),
                    ),
                    child: Column(
                      children: [
                        for (final (index, entry) in _entries.indexed) ...[
                          if (index != 0)
                            Divider(
                              height: RBorderWidth.thin,
                              thickness: RBorderWidth.thin,
                              color: c.border,
                            ),
                          _ProfileEntry(label: entry.$1, icon: entry.$2),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: RSpace.s4),
                  RButton(
                    label: 'تسجيل الخروج',
                    icon: Icons.logout,
                    kind: RButtonKind.secondary,
                    loading: _signingOut,
                    onPressed: _confirmingSignOut ? null : _confirmSignOut,
                  ),
                  const SizedBox(height: RSpace.s4),
                  Text(
                    // Matches pubspec's release; no platform or network lookup.
                    'الإصدار 1.0.0',
                    textAlign: TextAlign.center,
                    style: RType.caption.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ),
    );
  }
}

const _entries = [
  ('تعديل الاسم والبريد', Icons.edit_outlined),
  ('تغيير كلمة المرور', Icons.lock_outline),
  ('خصوصية بياناتي', Icons.verified_user_outlined),
  ('شروط الاستخدام وسياسة الخصوصية', Icons.description_outlined),
];

class _ProfileEntry extends StatelessWidget {
  const _ProfileEntry({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: false,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: RSpace.s14),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: RSpace.s4,
          vertical: RSpace.s2,
        ),
        child: Row(
          children: [
            Icon(icon, size: RSpace.s6, color: context.c.textSecondary),
            const SizedBox(width: RSpace.s3),
            Expanded(
              child: Text(
                label,
                style: RType.body.copyWith(color: context.c.textPrimary),
              ),
            ),
            const SizedBox(width: RSpace.s2),
            Icon(
              Icons.arrow_forward_ios,
              size: RSpace.s4,
              color: context.c.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
