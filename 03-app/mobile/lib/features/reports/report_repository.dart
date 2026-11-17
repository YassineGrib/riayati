import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import 'file_rules.dart';
import 'report.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider)),
);

class ReportRepository {
  ReportRepository(this.api, {this.tempDir});

  final ApiClient api;
  final Directory? tempDir;

  Directory get effectiveTempDir => tempDir ?? Directory.systemTemp;

  Future<Report> create({
    required String description,
    required DateTime incidentAt,
    required List<PickedFile> files,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (description.length < 3 || description.length > 5000) {
      throw const ApiError(
        message: 'يجب أن يكون وصف الواقعة بين 3 و5000 حرف.',
        fields: {
          'description': ['يجب أن يكون وصف الواقعة بين 3 و5000 حرف.'],
        },
      );
    }

    if (incidentAt.isAfter(DateTime.now())) {
      throw const ApiError(
        message: 'اختر تاريخ ووقت حادثة في الماضي أو الوقت الحاضر.',
        fields: {
          'incident_at': ['لا يمكن أن يكون موعد الحادثة في المستقبل.'],
        },
      );
    }

    final formData = FormData();
    formData.fields.add(MapEntry('description', description));
    formData.fields.add(MapEntry('incident_at', incidentAt.toIso8601String()));

    for (final file in files) {
      final ioFile = File(file.path);
      if (ioFile.existsSync()) {
        formData.files.add(
          MapEntry(
            'files[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.name,
            ),
          ),
        );
      } else {
        formData.files.add(
          MapEntry(
            'files[]',
            MultipartFile.fromBytes(
              const [],
              filename: file.name,
            ),
          ),
        );
      }
    }

    final json = await api.post<Map<String, dynamic>>(
      '/reports',
      data: formData,
      onSendProgress: onProgress,
    );

    return Report.fromJson(json['report'] as Map<String, dynamic>);
  }

  Future<List<Report>> list({ReportStatus? status}) async {
    final query = <String, dynamic>{};
    if (status != null) {
      query['status'] = status.value;
    }

    final json = await api.get<Map<String, dynamic>>(
      '/reports',
      queryParameters: query.isEmpty ? null : query,
    );

    final rawReports = json['reports'] as List? ?? const [];
    return rawReports
        .map((e) => Report.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Report> get(int id) async {
    final json = await api.get<Map<String, dynamic>>('/reports/$id');
    return Report.fromJson(json['report'] as Map<String, dynamic>);
  }

  Future<File> pdf(int id) async {
    final bytes = await api.getBytes('/reports/$id/pdf');
    // A real PDF always starts with "%PDF"; anything else (an error page, an
    // empty body) must not be handed to a PDF viewer as a blank document.
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46) {
      throw const ApiError(message: 'تعذر تحميل PDF. حاول مجددًا.');
    }
    final file = File('${effectiveTempDir.path}/report-$id.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uri> attachmentLink(int reportId, int attachmentId) async {
    final json = await api.get<Map<String, dynamic>>(
      '/reports/$reportId/attachments/$attachmentId/link',
    );
    return Uri.parse(json['url'] as String);
  }
}
