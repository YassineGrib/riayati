import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart' show linkSkipStoreProvider, tokenStoreProvider;
import 'package:riayati/core/router.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/auth/auth_controller.dart';

import 'family_test_support.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('invite code and server expiry render in $brightness', (
      tester,
    ) async {
      final api = FamilyTestApi();
      await pumpFamilyApp(tester, api, brightness: brightness);
      expect(find.text('K7M-4Q2'), findsOneWidget);
      expect(find.textContaining('2026/11/19'), findsOneWidget);
      expect(api.invites, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('skip is remembered for the next start', (tester) async {
    final api = FamilyTestApi();
    final container = await pumpFamilyApp(tester, api);
    final store = container.read(linkSkipStoreProvider) as MemoryLinkSkipStore;
    expect(store.skipped, isFalse);

    await tapFamilyButton(tester, 'تخطي الآن');
    await tester.pumpAndSettle();
    expect(store.skipped, isTrue);

    // A later start reads the flag and goes straight in.
    await container.read(authControllerProvider.notifier).refresh();
    expect(container.read(authControllerProvider).linkSkipped, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skip lets an unlinked parent into the app', (tester) async {
    final api = FamilyTestApi();
    final container = await pumpFamilyApp(tester, api);
    final router = container.read(routerProvider);
    expect(router.routeInformationProvider.value.uri.path, '/link');
    expect(container.read(authControllerProvider).linkSkipped, isFalse);

    await tapFamilyButton(tester, 'تخطي الآن');

    expect(container.read(authControllerProvider).linkSkipped, isTrue);
    expect(container.read(authControllerProvider).user!.linked, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    // The link screen stays reachable from the calendar and the profile.
    router.go('/link');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/link');
    // A server "not linked" answer must not push a skipping parent back.
    container.read(apiClientProvider).onNotLinked?.call();
    router.go('/reports');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/reports');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('bad code shows server message below field and permits retry', (
    tester,
  ) async {
    const message = 'رمز الدعوة غير صالح أو انتهت صلاحيته.';
    final api = FamilyTestApi()
      ..linkError = const ApiError(
        message: message,
        status: 422,
        fields: {
          'code': ['تحقق من رمز الدعوة.'],
        },
      );
    await pumpFamilyApp(tester, api);
    await tester.enterText(find.byType(TextFormField), ' BAD-CODE ');
    await tapFamilyButton(tester, 'ربط الحساب');
    expect(api.linkedCodes, ['BAD-CODE']);
    expect(find.text(message), findsOneWidget);
    expect(find.text('تحقق من رمز الدعوة.'), findsOneWidget);
    // Selection changes are not edits and must not dismiss server errors.
    final controller = tester
        .widget<TextFormField>(find.byType(TextFormField))
        .controller!;
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(message)).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextFormField)).dy),
    );
    await tapFamilyButton(tester, 'ربط الحساب');
    expect(api.linkedCodes.length, 2);
    expect(api.invites, 1);
    await tester.enterText(find.byType(TextFormField), 'ANOTHER');
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('blank code keeps linking disabled', (tester) async {
    final api = FamilyTestApi();
    await pumpFamilyApp(tester, api);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();
    final button = tester.widget<RButton>(
      find.byWidgetPredicate(
        (widget) => widget is RButton && widget.label == 'ربط الحساب',
      ),
    );
    expect(button.onPressed, isNull);
    expect(api.linkedCodes, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('successful link refreshes auth and guard lands on home', (
    tester,
  ) async {
    final api = FamilyTestApi();
    final container = await pumpFamilyApp(tester, api);
    await tester.enterText(find.byType(TextFormField), 'ABC-123');
    await tapFamilyButton(tester, 'ربط الحساب');
    expect(container.read(authControllerProvider).user!.linked, isTrue);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('copy writes invite code and shows snackbar', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpFamilyApp(tester, FamilyTestApi());
    await tapFamilyButton(tester, 'نسخ');
    expect(copied, 'K7M-4Q2');
    expect(find.text('تم نسخ الرمز'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invite failure has retry; sign out remains available', (
    tester,
  ) async {
    final api = FamilyTestApi()
      ..inviteError = const ApiError(message: ApiError.offlineMessage);
    final container = await pumpFamilyApp(tester, api);
    expect(find.text(ApiError.offlineMessage), findsOneWidget);
    expect(api.invites, 1);
    expect(
      tester
          .widget<RButton>(
            find.byWidgetPredicate(
              (widget) => widget is RButton && widget.label == 'تسجيل الخروج',
            ),
          )
          .onPressed,
      isNotNull,
    );
    // A failed POST must stay failed until the user explicitly requests retry.
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(api.invites, 1);
    api.inviteError = null;
    await tapFamilyButton(tester, 'إعادة المحاولة');
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(ApiError.offlineMessage), findsNothing);
    expect(find.text('K7M-4Q2'), findsOneWidget);
    expect(api.invites, 2);
    await tapFamilyButton(tester, 'تسجيل الخروج');
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/welcome',
    );
    expect(container.read(authControllerProvider).status, AuthStatus.signedOut);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('one invite per screen opening, not per edit or rebuild', (
    tester,
  ) async {
    final api = FamilyTestApi();
    final container = await pumpFamilyApp(tester, api);
    expect(api.invites, 1);
    for (final code in ['ABC', 'ABC-123', '']) {
      await tester.enterText(find.byType(TextFormField), code);
      await tester.pumpAndSettle();
      expect(api.invites, 1);
      expect(find.text('K7M-4Q2'), findsOneWidget);
    }
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(api.invites, 1);
    await tapFamilyButton(tester, 'تسجيل الخروج');
    await container.read(tokenStoreProvider).write('next-session');
    await container.read(authControllerProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(api.invites, 2);
    expect(find.text('K7M-4Q2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
