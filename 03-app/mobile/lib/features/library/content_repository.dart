import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'content_item.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(apiClientProvider)),
);

class ContentRepository {
  ContentRepository(this.api);

  final ApiClient api;

  Future<List<ContentItem>> list({
    ContentType? type,
    String? query,
    int? page,
  }) async {
    final params = <String, dynamic>{};
    if (type != null) {
      params['type'] = type.value;
    }
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (page != null && page > 1) {
      params['page'] = page;
    }

    final json = await api.get<Map<String, dynamic>>(
      '/contents',
      queryParameters: params.isEmpty ? null : params,
    );

    final rawList = json['data'] as List? ?? const [];
    return rawList
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContentItem> get(String slug) async {
    final json = await api.get<Map<String, dynamic>>('/contents/$slug');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ContentItem.fromJson(data);
  }
}
