import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riayati/core/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  test('date and time are separate isolated runs with Latin digits', () {
    final text = formatDateTime(DateTime(2026, 11, 20, 11, 34));
    expect(text, contains('\u2067'));
    expect(text, contains('2026'));
    expect(text, contains('\u206611:34\u2069'));
    expect(text, isNot(contains('٢')));
  });

  test('UTC values are shown in the device time zone', () {
    final utc = DateTime.utc(2026, 11, 20, 10, 34);
    final local = utc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    expect(formatDateTime(utc), contains('$hh:$mm'));
  });

  test('file names and sizes stay in one left-to-right run', () {
    expect(isolateLtr('53.jpg'), '\u206653.jpg\u2069');
    expect(formatFileSize(143 * 1024), '\u2066143 KB\u2069');
    expect(formatFileSize(5 * 1024 * 1024), '\u20665.0 MB\u2069');
  });
}
