import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'support_center.dart';

final centerRepositoryProvider = Provider<CenterRepository>(
  (ref) => CenterRepository(ref.watch(apiClientProvider)),
);

class CenterRepository {
  CenterRepository(this.api);

  final ApiClient api;

  Future<List<SupportCenter>> list({
    CenterKind? kind,
    String? wilaya,
    String? query,
  }) async {
    final params = <String, dynamic>{};
    if (kind != null) {
      params['kind'] = kind.value;
    }
    if (wilaya != null && wilaya.isNotEmpty) {
      params['wilaya'] = wilaya;
    }
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    final json = await api.get<Map<String, dynamic>>(
      '/centers',
      queryParameters: params.isEmpty ? null : params,
    );

    final rawList = json['data'] as List? ?? const [];
    return rawList
        .map((e) => SupportCenter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportCenter> get(int id) async {
    final json = await api.get<Map<String, dynamic>>('/centers/$id');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return SupportCenter.fromJson(data);
  }
}
