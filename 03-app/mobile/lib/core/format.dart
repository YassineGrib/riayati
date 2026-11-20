import 'package:intl/intl.dart' hide TextDirection;

/// Keeps [text] (digits, dates, file names) as one unit inside right-to-left
/// text, so numbers and separators are not reordered by the bidi algorithm.
String isolateLtr(String text) => '\u2066$text\u2069';

/// Keeps an Arabic phrase as one unit inside left-to-right runs.
String isolateRtl(String text) => '\u2067$text\u2069';

/// "20 نوفمبر 2026 · 11:34" in the device time zone, Latin digits everywhere
/// so every screen shows the same thing.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final String date;
  try {
    date = (DateFormat('d MMMM yyyy', 'ar')..useNativeDigits = false).format(
      local,
    );
  } catch (_) {
    return _fallback(local);
  }
  final time = DateFormat('HH:mm', 'en').format(local);
  return '${isolateRtl(date)}  ·  ${isolateLtr(time)}';
}

String _fallback(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return isolateLtr(
    '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}',
  );
}

/// "الأربعاء 25 نوفمبر" (or with the year), Latin digits like the calendar.
String formatDay(DateTime value, {bool weekday = false, bool year = false}) {
  final pattern = '${weekday ? 'EEEE ' : ''}d MMMM${year ? ' yyyy' : ''}';
  try {
    return isolateRtl(
      (DateFormat(pattern, 'ar')..useNativeDigits = false).format(value),
    );
  } catch (_) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }
}

/// Correct Arabic count wording for attachments.
String attachmentsLabel(int count) {
  if (count <= 0) return 'بدون مرفقات';
  if (count == 1) return 'مرفق واحد';
  if (count == 2) return 'مرفقان';
  if (count <= 10) return '$count مرفقات';
  return '$count مرفقًا';
}

/// "143 KB" / "1.2 MB" kept as one run.
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return isolateLtr('${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB');
  }
  return isolateLtr('${(bytes / 1024).toStringAsFixed(0)} KB');
}
