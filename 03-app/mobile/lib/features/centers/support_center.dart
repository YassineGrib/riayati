import '../profile/wilayas.dart';

enum CenterKind {
  court('court', 'محكمة'),
  legalAid('legal_aid', 'مساعدة قانونية'),
  childProtection('child_protection', 'حماية الطفولة'),
  psychological('psychological', 'دعم نفسي'),
  social('social', 'مصالح اجتماعية'),
  ngo('ngo', 'جمعية'),
  hotline('hotline', 'خط مساعدة');

  const CenterKind(this.value, this.label);
  final String value;
  final String label;

  static CenterKind? fromString(String? val) {
    if (val == null) return null;
    for (final k in CenterKind.values) {
      if (k.value == val) return k;
    }
    return null;
  }
}

class SupportCenter {
  const SupportCenter({
    required this.id,
    required this.name,
    required this.kind,
    required this.kindLabel,
    this.wilaya,
    this.address,
    this.phone,
    this.hotline,
    this.email,
    this.website,
    this.hours,
    this.notes,
  });

  final int id;
  final String name;
  final CenterKind kind;
  final String kindLabel;
  final String? wilaya;
  final String? address;
  final String? phone;
  final String? hotline;
  final String? email;
  final String? website;
  final String? hours;
  final String? notes;

  String? get wilayaLabel {
    if (wilaya == null) return null;
    final wNumber = int.tryParse(wilaya!);
    if (wNumber != null) {
      for (final w in wilayas) {
        if (w.number == wNumber) {
          return w.label;
        }
      }
    }
    return wilaya;
  }

  factory SupportCenter.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String?;
    final resolvedKind = CenterKind.fromString(kindStr) ?? CenterKind.court;
    final rawWilaya = json['wilaya'];
    return SupportCenter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      kind: resolvedKind,
      kindLabel: json['kind_label'] as String? ?? resolvedKind.label,
      wilaya: rawWilaya?.toString(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      hotline: json['hotline'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      hours: json['hours'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.value,
    'kind_label': kindLabel,
    if (wilaya != null) 'wilaya': wilaya,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (hotline != null) 'hotline': hotline,
    if (email != null) 'email': email,
    if (website != null) 'website': website,
    if (hours != null) 'hours': hours,
    if (notes != null) 'notes': notes,
  };
}
