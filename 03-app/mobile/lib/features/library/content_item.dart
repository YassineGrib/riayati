enum ContentType {
  article('article', 'مقال'),
  law('law', 'قانون'),
  ruling('ruling', 'اجتهاد قضائي'),
  guide('guide', 'دليل');

  const ContentType(this.value, this.label);
  final String value;
  final String label;

  static ContentType? fromString(String? val) {
    if (val == null) return null;
    for (final t in ContentType.values) {
      if (t.value == val) return t;
    }
    return null;
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.slug,
    this.category,
    this.reference,
    this.summary,
    this.publishedAt,
    this.body,
  });

  final int id;
  final ContentType type;
  final String typeLabel;
  final String title;
  final String slug;
  final String? category;
  final String? reference;
  final String? summary;
  final DateTime? publishedAt;
  final String? body;

  static String stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', ' - ')
        .replaceAll('&ndash;', ' - ');
    return text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String get cleanBody {
    final raw = body ?? summary ?? '';
    return stripHtml(raw);
  }

  int get readingTimeMinutes {
    final text = cleanBody;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 150).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final resolvedType = ContentType.fromString(typeStr) ?? ContentType.article;
    final rawDate = json['published_at'] as String?;
    return ContentItem(
      id: json['id'] as int,
      type: resolvedType,
      typeLabel: json['type_label'] as String? ?? resolvedType.label,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String?,
      reference: json['reference'] as String?,
      summary: json['summary'] as String?,
      publishedAt: rawDate != null ? DateTime.tryParse(rawDate) : null,
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'type_label': typeLabel,
    'title': title,
    'slug': slug,
    if (category != null) 'category': category,
    if (reference != null) 'reference': reference,
    if (summary != null) 'summary': summary,
    if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
    if (body != null) 'body': body,
  };
}
