import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/app_scaffold.dart';
import 'package:riayati/core/widgets/floating_nav.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/core/widgets/r_card.dart';
import 'package:riayati/core/widgets/r_text_field.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/core/widgets/status_chip.dart';
import 'package:riayati/core/widgets/watermark.dart';

import '../widgets/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load the actual embedded fonts: Ahem cannot validate Arabic typography.
    for (final (family, prefix) in [
      ('ThmanyahSans', 'thmanyahsans'),
      ('ThmanyahSerifDisplay', 'thmanyahserifdisplay'),
      ('ThmanyahSerifText', 'thmanyahseriftext'),
    ]) {
      final loader = FontLoader(family);
      for (final weight in ['Light', 'Regular', 'Medium', 'Bold', 'Black']) {
        loader.addFont(
          rootBundle.load('assets/fonts/thmanyah/$prefix-$weight.otf'),
        );
      }
      await loader.load();
    }
    final fallback = FontLoader('IBMPlexSansArabic')
      ..addFont(
        rootBundle.load('assets/fonts/plex/IBMPlexSansArabic-Regular.ttf'),
      )
      ..addFont(
        rootBundle.load('assets/fonts/plex/IBMPlexSansArabic-Bold.ttf'),
      );
    await fallback.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Widget padded(Widget child) =>
      Padding(padding: const EdgeInsetsDirectional.all(24), child: child);

  final samples = <String, Widget Function()>{
    'r_button': () => padded(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in RButtonKind.values) ...[
            RButton(
              label: kind == RButtonKind.sos
                  ? 'الإبلاغ عن حادثة'
                  : 'تسجيل الدخول',
              kind: kind,
              icon: Icons.add,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
          ],
          const RButton(label: 'متابعة'),
          const SizedBox(height: 16),
          RButton(label: 'جارٍ الإرسال', loading: true, onPressed: () {}),
        ],
      ),
    ),
    'r_text_field': () => padded(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RTextField(
            label: 'البريد الإلكتروني',
            helper: 'أدخل بريدك الإلكتروني',
            keyboardType: TextInputType.emailAddress,
          ),
          const RTextField(label: 'كلمة المرور', obscure: true),
          Form(
            autovalidateMode: AutovalidateMode.always,
            child: RTextField(
              label: 'الاسم',
              validator: (_) => 'هذا الحقل مطلوب',
            ),
          ),
        ],
      ),
    ),
    'r_card': () => padded(
      const RCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الزيارة القادمة'),
            SizedBox(height: 12),
            Text('الجمعة 20 نوفمبر'),
            Text('10:00 – 14:00 · اقترحها الطرف الآخر'),
          ],
        ),
      ),
    ),
    'status_chip': () => padded(
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final tone in StatusTone.values)
            StatusChip(
              label: switch (tone) {
                StatusTone.neutral => 'RIA-2026-0142',
                StatusTone.info => 'قيد المراجعة',
                StatusTone.success => 'تمت المراجعة',
                StatusTone.warning => 'بانتظار ردّك',
                StatusTone.error => 'تعذر الإرسال',
              },
              tone: tone,
            ),
        ],
      ),
    ),
    'watermark': () => const Watermark(),
    'floating_nav': () => Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: FloatingNav(index: 1, onTap: (_) {}),
    ),
    'app_scaffold': () => AppScaffold(
      title: 'بلاغاتي',
      body: const RCard(child: Text('متابعة بلاغاتك وحالة كل بلاغ')),
      bottom: FloatingNav(index: 1, onTap: (_) {}),
    ),
    'error_view': () => padded(
      ErrorView(
        message: 'تعذر الاتصال. تحقق من اتصالك بالإنترنت.',
        onRetry: () {},
      ),
    ),
    'loading_view': () => const LoadingView(),
    'empty_view': () => padded(
      EmptyView(
        title: 'لا توجد بلاغات بعد',
        body: 'عند توثيق حادثة ستظهر هنا بلاغاتك مع حالة كل بلاغ.',
        action: RButton(label: 'بلاغ جديد', icon: Icons.add, onPressed: () {}),
      ),
    ),
  };

  for (final brightness in Brightness.values) {
    for (final sample in samples.entries) {
      testWidgets('${sample.key} ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          testApp(
            RepaintBoundary(
              key: const ValueKey('golden'),
              child: SizedBox.expand(child: sample.value()),
            ),
            brightness: brightness,
          ),
        );
        // A fixed frame also captures indeterminate progress deterministically.
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('${sample.key}_${brightness.name}.png'),
        );
      });
    }
  }
}
