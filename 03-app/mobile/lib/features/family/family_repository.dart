import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../auth/auth_controller.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(
    ref.watch(apiClientProvider),
    refreshAuth: () => ref.read(authControllerProvider.notifier).refresh(),
  ),
);

class InviteCode {
  const InviteCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
    code: json['code'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );
}

class FamilyRepository {
  FamilyRepository(this.api, {required this.refreshAuth});

  final ApiClient api;
  final Future<void> Function() refreshAuth;

  Future<InviteCode> invite() async => InviteCode.fromJson(
    await api.post<Map<String, dynamic>>('/family/invite'),
  );

  Future<void> link(String code) async {
    await api.post<dynamic>('/family/link', data: {'code': code.trim()});
    // The router observes auth state and leaves /link only after /me confirms it.
    await refreshAuth();
  }
}
