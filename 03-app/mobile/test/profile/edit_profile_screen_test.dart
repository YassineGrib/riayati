import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/auth/auth_controller.dart';
import 'package:riayati/features/auth/auth_repository.dart';
import 'package:riayati/features/auth/user.dart';
import 'package:riayati/features/profile/edit_profile_screen.dart';
import 'package:riayati/features/profile/profile_screen.dart';
import 'package:riayati/features/profile/wilayas.dart';

import '../api/api_client_test.dart' show MemoryTokenStore;

const _user = User(
  id: 1,
  name: 'أمينة',
  email: 'amina@example.com',
  role: 'mother',
  linked: false,
);

class _Auth extends AuthController {
  @override
  AuthState build() {
    super.build();
    return const AuthState.signedIn(_user);
  }
}

class _Repository extends AuthRepository {
  _Repository()
    : super(ApiClient(tokenStore: MemoryTokenStore()), MemoryTokenStore());
  ApiError? error;
  Map<String, dynamic>? submitted;
  @override
  Future<User> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? wilaya,
    int? childrenCount,
    String? currentPassword,
  }) async {
    submitted = {
      'name': name,
      'email': email,
      'phone': phone,
      'wilaya': wilaya,
      'children_count': childrenCount,
      'current_password': currentPassword,
    };
    if (error != null) throw error!;
    return User(
      id: 1,
      name: name,
      email: email,
      role: 'mother',
      linked: false,
      phone: phone,
      wilaya: wilaya,
      childrenCount: childrenCount,
    );
  }
}

Future<GoRouter> _pump(WidgetTester tester, _Repository repository) async {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(_Auth.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(Brightness.light),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Finder _field(String name) => find.descendant(
  of: find.byKey(ValueKey(name)),
  matching: find.byType(TextFormField),
);
Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('حفظ التعديلات'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('حفظ التعديلات'));
  await tester.pumpAndSettle();
}

void main() {
  test('58 numbered wilayas are unique', () {
    expect(wilayas.length, 58);
    expect(wilayas.map((w) => w.name).toSet().length, 58);
    expect(wilayas.first.number, 1);
    expect(wilayas.last.number, 58);
  });

  testWidgets(
    'profile shows missing details and edit pushes screen with back',
    (tester) async {
      final router = await _pump(tester, _Repository());
      expect(find.text('غير محدد'), findsNWidgets(3));
      for (final label in ['رقم الهاتف', 'الولاية', 'عدد الأطفال']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.ensureVisible(find.text('تعديل'));
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
    },
  );

  testWidgets('validates name email and phone before submitting', (
    tester,
  ) async {
    final repository = _Repository();
    final router = await _pump(tester, repository);
    router.push('/profile/edit');
    await tester.pumpAndSettle();
    await tester.enterText(_field('name'), 'أ');
    await tester.enterText(_field('email'), 'bad');
    // Changing email inserts the password field before phone. Rebuild before
    // focusing phone so text input reaches its current EditableText instance.
    await tester.pumpAndSettle();
    await tester.ensureVisible(_field('phone'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('phone'), '123');
    expect(
      tester.widget<TextFormField>(_field('phone')).controller!.text,
      '123',
    );
    await _save(tester);
    expect(repository.submitted, isNull);
    expect(find.text('الاسم من حرفين إلى 80 حرفًا.'), findsOneWidget);
    expect(find.text('أدخل بريدًا إلكترونيًا صحيحًا.'), findsOneWidget);
    expect(find.text('أدخل رقم هاتف جزائري صحيحًا.'), findsOneWidget);
  });

  testWidgets('email change asks for password and reverting hides it', (
    tester,
  ) async {
    final repository = _Repository();
    final router = await _pump(tester, repository);
    router.push('/profile/edit');
    await tester.pumpAndSettle();
    expect(_field('current_password'), findsNothing);
    await tester.enterText(_field('email'), 'new@example.com');
    await tester.pump();
    expect(_field('current_password'), findsOneWidget);
    await _save(tester);
    expect(repository.submitted, isNull);
    expect(find.text('كلمة المرور الحالية مطلوبة.'), findsOneWidget);
    await tester.enterText(_field('email'), 'amina@example.com');
    await tester.pump();
    expect(_field('current_password'), findsNothing);
  });

  testWidgets(
    'search picker, stepper and save refresh profile without another GET',
    (tester) async {
      final repository = _Repository();
      final router = await _pump(tester, repository);
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      await tester.enterText(_field('name'), 'أمينة الجديدة');
      await tester.enterText(_field('phone'), '0555123456');
      await tester.ensureVisible(find.byKey(const ValueKey('wilaya')));
      await tester.tap(find.byKey(const ValueKey('wilaya')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('wilaya_search')), '16');
      await tester.pumpAndSettle();
      await tester.tap(find.text('16 - الجزائر'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('زيادة عدد الأطفال'));
      await tester.tap(find.byTooltip('زيادة عدد الأطفال'));
      await tester.pump();
      await _save(tester);
      expect(repository.submitted?['wilaya'], 'الجزائر');
      expect(repository.submitted?['children_count'], 1);
      expect(repository.submitted?['current_password'], isNull);
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      for (final value in [
        'أمينة الجديدة',
        '0555123456',
        'الجزائر',
        '1',
        'تم تحديث بيانات الحساب بنجاح.',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
    },
  );

  testWidgets(
    'server errors appear below fields and password is submitted for email change',
    (tester) async {
      final repository = _Repository()
        ..error = const ApiError(
          message: 'تحقق من الحقول',
          status: 422,
          fields: {
            'name': ['الاسم غير صالح'],
            'email': ['البريد مستخدم'],
            'phone': ['الهاتف غير صالح'],
            'wilaya': ['الولاية غير صالحة'],
            'children_count': ['عدد غير صالح'],
            'current_password': ['كلمة المرور غير صحيحة'],
          },
        );
      final router = await _pump(tester, repository);
      router.push('/profile/edit');
      await tester.pumpAndSettle();
      await tester.enterText(_field('email'), 'new@example.com');
      await tester.pump();
      await tester.enterText(_field('current_password'), 'secret');
      await _save(tester);
      expect(repository.submitted?['current_password'], 'secret');
      for (final message in repository.error!.fields.values.expand((e) => e)) {
        expect(find.text(message), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('البريد مستخدم')).dy,
        greaterThan(tester.getTopLeft(_field('email')).dy),
      );
      repository.error = null;
      await _save(tester);
      expect(find.text('new@example.com'), findsOneWidget);
    },
  );

  testWidgets('children stepper stays within 0 to 20 and can be cleared', (
    tester,
  ) async {
    final repository = _Repository();
    final router = await _pump(tester, repository);
    router.push('/profile/edit');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('لا يوجد أطفال'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لا يوجد أطفال'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
          .onPressed,
      isNull,
    );
    for (var i = 0; i < 20; i++) {
      await tester.ensureVisible(find.byTooltip('زيادة عدد الأطفال'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('زيادة عدد الأطفال'));
      await tester.pumpAndSettle();
    }
    expect(find.text('20'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('إلغاء التحديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء التحديد'));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد أطفال'), findsOneWidget);
    await _save(tester);
    expect(repository.submitted, isNotNull);
    expect(repository.submitted?['children_count'], isNull);
  });
}
