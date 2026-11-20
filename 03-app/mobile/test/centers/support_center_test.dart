import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/features/centers/support_center.dart';

void main() {
  group('SupportCenter', () {
    test('parses from and to JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'محكمة سيدي امحمد - قسم الأسرة',
        'kind': 'court',
        'kind_label': 'محكمة',
        'wilaya': '16',
        'address': 'شارع عبان رمضان، الجزائر العاصمة',
        'phone': '000-000-000',
        'hotline': '11-11',
        'email': 'contact@court.dz',
        'website': 'https://court.dz',
        'hours': 'الأحد إلى الخميس: 08:30 – 16:30',
        'notes': 'النظر في دعاوى الحضانة والزيارة والنفقة.',
      };

      final center = SupportCenter.fromJson(json);

      expect(center.id, 1);
      expect(center.name, 'محكمة سيدي امحمد - قسم الأسرة');
      expect(center.kind, CenterKind.court);
      expect(center.kindLabel, 'محكمة');
      expect(center.wilaya, '16');
      expect(center.wilayaLabel, '16 - الجزائر');
      expect(center.address, 'شارع عبان رمضان، الجزائر العاصمة');
      expect(center.phone, '000-000-000');
      expect(center.hotline, '11-11');
      expect(center.email, 'contact@court.dz');
      expect(center.website, 'https://court.dz');
      expect(center.hours, 'الأحد إلى الخميس: 08:30 – 16:30');
      expect(center.notes, 'النظر في دعاوى الحضانة والزيارة والنفقة.');

      final outJson = center.toJson();
      expect(outJson['id'], 1);
      expect(outJson['kind'], 'court');
      expect(outJson['wilaya'], '16');
    });

    test('wilayaLabel returns raw string when non-numeric', () {
      const center = SupportCenter(
        id: 2,
        name: 'مركز عام',
        kind: CenterKind.ngo,
        kindLabel: 'جمعية',
        wilaya: 'الجزائر العاصمة',
      );
      expect(center.wilayaLabel, 'الجزائر العاصمة');
    });

    test('parses all CenterKind values', () {
      expect(CenterKind.court.value, 'court');
      expect(CenterKind.legalAid.value, 'legal_aid');
      expect(CenterKind.childProtection.value, 'child_protection');
      expect(CenterKind.psychological.value, 'psychological');
      expect(CenterKind.social.value, 'social');
      expect(CenterKind.ngo.value, 'ngo');
      expect(CenterKind.hotline.value, 'hotline');

      expect(CenterKind.fromString('court'), CenterKind.court);
      expect(CenterKind.fromString('legal_aid'), CenterKind.legalAid);
      expect(CenterKind.fromString('child_protection'), CenterKind.childProtection);
      expect(CenterKind.fromString('unknown'), isNull);
    });
  });
}
