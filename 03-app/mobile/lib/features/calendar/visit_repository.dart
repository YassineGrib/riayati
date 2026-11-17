import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'visit.dart';

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepository(ref.watch(apiClientProvider)),
);

class VisitRepository {
  VisitRepository(this.api);

  final ApiClient api;

  Future<List<Visit>> month(String ym) async {
    final json = await api.get<Map<String, dynamic>>(
      '/visits',
      queryParameters: {'month': ym},
    );
    final raw = json['visits'] as List? ?? const [];
    return raw
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visit>> upcoming() async {
    final json = await api.get<Map<String, dynamic>>('/visits/upcoming');
    final raw = json['visits'] as List? ?? const [];
    return raw
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Visit> get(int id) async {
    final json = await api.get<Map<String, dynamic>>('/visits/$id');
    return Visit.fromJson(json['visit'] as Map<String, dynamic>);
  }

  Future<Visit> propose({
    required String date,
    required String from,
    required String to,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'date': date,
      'from': from,
      'to': to,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final json = await api.post<Map<String, dynamic>>('/visits', data: data);
    return Visit.fromJson(json['visit'] as Map<String, dynamic>);
  }

  Future<Visit> accept(int id) async {
    final json = await api.post<Map<String, dynamic>>('/visits/$id/accept');
    return Visit.fromJson(json['visit'] as Map<String, dynamic>);
  }

  Future<Visit> decline(int id) async {
    final json = await api.post<Map<String, dynamic>>('/visits/$id/decline');
    return Visit.fromJson(json['visit'] as Map<String, dynamic>);
  }

  Future<Visit> confirm(int id) async {
    final json = await api.post<Map<String, dynamic>>('/visits/$id/confirm');
    return Visit.fromJson(json['visit'] as Map<String, dynamic>);
  }
}
