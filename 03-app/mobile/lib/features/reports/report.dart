enum ReportStatus {
  underReview('under_review', 'قيد المراجعة'),
  reviewed('reviewed', 'تمت المراجعة');

  const ReportStatus(this.value, this.label);
  final String value;
  final String label;

  static ReportStatus fromValue(String value) {
    for (final status in ReportStatus.values) {
      if (status.value == value) return status;
    }
    return ReportStatus.underReview;
  }
}

class ReportAttachment {
  const ReportAttachment({
    required this.id,
    required this.filename,
    required this.mime,
    required this.size,
    required this.sha256,
    this.kind,
  });

  final int id;
  final String filename;
  final String mime;
  final int size;
  final String sha256;
  final String? kind;

  String get name => filename;

  factory ReportAttachment.fromJson(Map<String, dynamic> json) =>
      ReportAttachment(
        id: json['id'] as int,
        filename: (json['name'] ?? json['filename'] ?? '') as String,
        mime: (json['mime'] ?? '') as String,
        size: json['size'] as int? ?? 0,
        sha256: (json['sha256'] ?? '') as String,
        kind: json['kind'] as String?,
      );
}

class Report {
  const Report({
    required this.id,
    required this.reference,
    required this.status,
    required this.incidentAt,
    this.description = '',
    this.excerpt,
    this.createdAt,
    this.attachmentsCount = 0,
    this.attachments = const [],
    this.statusLabel,
  });

  final int id;
  final String reference;
  final ReportStatus status;
  final DateTime incidentAt;
  final String description;
  final String? excerpt;
  final DateTime? createdAt;
  final int attachmentsCount;
  final List<ReportAttachment> attachments;
  final String? statusLabel;

  factory Report.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'under_review';
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
            .map((e) => ReportAttachment.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <ReportAttachment>[];

    return Report(
      id: json['id'] as int,
      reference: json['reference'] as String,
      status: ReportStatus.fromValue(statusStr),
      incidentAt: DateTime.parse(json['incident_at'] as String),
      description: (json['description'] as String?) ??
          (json['excerpt'] as String?) ??
          '',
      excerpt: json['excerpt'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      attachmentsCount:
          (json['attachments_count'] as int?) ?? attachments.length,
      attachments: attachments,
      statusLabel: json['status_label'] as String?,
    );
  }
}
