import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/features/library/content_item.dart';

void main() {
  group('ContentItem', () {
    test('parses from and to JSON correctly', () {
      final json = {
        'id': 1,
        'type': 'law',
        'type_label': 'قانون',
        'title': 'شروط استحقاق الحضانة وسقوطها',
        'slug': 'custody-eligibility',
        'category': 'قانون الأسرة',
        'reference': 'المواد 64، 65 و66',
        'summary': 'ملخص لأهم المواد المنظمة للحضانة.',
        'published_at': '2026-11-18T10:00:00.000Z',
        'body': '<p>الحضانة هي حفظ الولد وتربيته.</p><br><div>وتسقط الحضانة إذا اختلت الشروط.</div>',
      };

      final item = ContentItem.fromJson(json);

      expect(item.id, 1);
      expect(item.type, ContentType.law);
      expect(item.typeLabel, 'قانون');
      expect(item.title, 'شروط استحقاق الحضانة وسقوطها');
      expect(item.slug, 'custody-eligibility');
      expect(item.category, 'قانون الأسرة');
      expect(item.reference, 'المواد 64، 65 و66');
      expect(item.summary, 'ملخص لأهم المواد المنظمة للحضانة.');
      expect(item.publishedAt, DateTime.parse('2026-11-18T10:00:00.000Z'));
      expect(item.cleanBody, 'الحضانة هي حفظ الولد وتربيته. وتسقط الحضانة إذا اختلت الشروط.');
      expect(item.readingTimeMinutes, 1);

      final outJson = item.toJson();
      expect(outJson['id'], 1);
      expect(outJson['type'], 'law');
      expect(outJson['slug'], 'custody-eligibility');
    });

    test('stripHtml cleans HTML tags and entity references', () {
      const html = '<article><h1>العنوان</h1><p>الفقرة الأولى &amp; الثانية &quot;مهمة&quot;.</p></article>';
      final text = ContentItem.stripHtml(html);
      expect(text, 'العنوان الفقرة الأولى & الثانية "مهمة".');
    });

    test('readingTimeMinutes calculates based on word count', () {
      final words = List.filled(300, 'كلمة').join(' ');
      final item = ContentItem(
        id: 2,
        type: ContentType.article,
        typeLabel: 'مقال',
        title: 'مقال تجريبي',
        slug: 'test-article',
        body: words,
      );

      expect(item.readingTimeMinutes, 2);
    });
  });
}
