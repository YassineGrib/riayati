enum VisitStatus {
  proposed('proposed', 'بانتظار الرد'),
  accepted('accepted', 'تم القبول'),
  declined('declined', 'مرفوضة'),
  confirmed('confirmed', 'مؤكدة');

  const VisitStatus(this.value, this.label);
  final String value;
  final String label;

  static VisitStatus fromValue(String value) {
    for (final status in VisitStatus.values) {
      if (status.value == value) return status;
    }
    return VisitStatus.proposed;
  }
}

class VisitTimelineEntry {
  const VisitTimelineEntry({
    required this.step,
    required this.at,
  });

  final String step;
  final DateTime at;

  factory VisitTimelineEntry.fromJson(Map<String, dynamic> json) =>
      VisitTimelineEntry(
        step: json['step'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}

class Visit {
  const Visit({
    required this.id,
    required this.date,
    required this.from,
    required this.to,
    this.note,
    required this.status,
    required this.proposedByMe,
    required this.needsMyResponse,
    required this.canConfirm,
    this.timeline = const [],
    this.startsAt,
    this.endsAt,
    this.statusLabel,
  });

  final int id;
  final String date;
  final String from;
  final String to;
  final String? note;
  final VisitStatus status;
  final bool proposedByMe;
  final bool needsMyResponse;
  final bool canConfirm;
  final List<VisitTimelineEntry> timeline;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? statusLabel;

  factory Visit.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'proposed';
    final rawTimeline = json['timeline'];
    final timeline = rawTimeline is List
        ? rawTimeline
            .map((e) => VisitTimelineEntry.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <VisitTimelineEntry>[];

    return Visit(
      id: json['id'] as int,
      date: json['date'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      note: json['note'] as String?,
      status: VisitStatus.fromValue(statusStr),
      proposedByMe: json['proposed_by_me'] as bool? ?? false,
      needsMyResponse: json['needs_my_response'] as bool? ?? false,
      canConfirm: json['can_confirm'] as bool? ?? false,
      timeline: timeline,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      statusLabel: json['status_label'] as String?,
    );
  }
}
