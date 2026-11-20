import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

class AssistantSource {
  const AssistantSource({
    required this.id,
    required this.title,
    this.reference,
    this.slug,
  });

  final int id;
  final String title;
  final String? reference;
  final String? slug;

  factory AssistantSource.fromJson(Map<String, dynamic> json) =>
      AssistantSource(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        reference: json['reference'] as String?,
        slug: json['slug'] as String?,
      );
}

class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.sufficient,
    this.sources = const [],
  });

  final String answer;
  final bool sufficient;
  final List<AssistantSource> sources;

  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
    answer: json['answer'] as String? ?? '',
    sufficient: json['sufficient'] as bool? ?? false,
    sources: (json['sources'] as List? ?? const [])
        .map((e) => AssistantSource.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(ref.watch(apiClientProvider)),
);

class AssistantRepository {
  AssistantRepository(this.api);

  final ApiClient api;

  /// Only the question leaves the phone: no case data, no account data.
  Future<AssistantReply> ask(String question) async {
    final json = await api.post<Map<String, dynamic>>(
      '/assistant',
      data: {'question': question.trim()},
    );
    return AssistantReply.fromJson(json);
  }
}
