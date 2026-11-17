import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import 'file_rules.dart';

final attachmentCompressorProvider = Provider<AttachmentCompressor>((ref) {
  return DefaultAttachmentCompressor();
});

abstract class AttachmentCompressor {
  Future<PickedFile> compress(
    PickedFile file, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  });
}

class FakeAttachmentCompressor implements AttachmentCompressor {
  FakeAttachmentCompressor({
    this.compressFactor = 0.5,
    this.shouldFail = false,
    this.delay = Duration.zero,
    this.reportProgress = true,
  });

  double compressFactor;
  bool shouldFail;
  Duration delay;
  bool reportProgress;
  int compressCalls = 0;
  PickedFile? lastCompressedInput;

  @override
  Future<PickedFile> compress(
    PickedFile file, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    compressCalls++;
    lastCompressedInput = file;

    final mime = file.mime.toLowerCase().split(';').first.trim();
    if (mime == 'application/pdf') {
      return file;
    }

    if (reportProgress && onProgress != null) {
      onProgress(0.2);
    }

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (isCancelled?.call() ?? false) {
      throw Exception('تم إلغاء الضغط');
    }

    if (reportProgress && onProgress != null) {
      onProgress(1.0);
    }

    if (shouldFail) {
      throw Exception('فشل ضغط الملف');
    }

    final newSize = (file.size * compressFactor).round();
    final newPath = file.path.endsWith('.compressed')
        ? file.path
        : '${file.path}.compressed';

    return PickedFile(
      path: newPath,
      name: file.name,
      size: newSize,
      mime: mime.startsWith('image/') ? 'image/jpeg' : mime,
    );
  }
}

class DefaultAttachmentCompressor implements AttachmentCompressor {
  @override
  Future<PickedFile> compress(
    PickedFile file, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final mime = file.mime.toLowerCase().split(';').first.trim();
    if (mime == 'application/pdf') {
      return file;
    }

    if (mime.startsWith('image/')) {
      // Keep small PNG screenshots with transparency as is (<= 1MB)
      if (mime == 'image/png' && file.size <= 1024 * 1024) {
        return file;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'\.[^\.]+$'), '')}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1920,
        minHeight: 1920,
        quality: 80,
        keepExif: true,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('تعذر ضغط الصورة');
      }

      final compressedFile = File(result.path);
      final length = await compressedFile.length();
      return PickedFile(
        path: result.path,
        name: '${file.name.replaceAll(RegExp(r'\.[^\.]+$'), '')}.jpg',
        size: length,
        mime: 'image/jpeg',
      );
    }

    if (mime.startsWith('video/')) {
      Subscription? subscription;
      if (onProgress != null) {
        subscription = VideoCompress.compressProgress$.subscribe((progress) {
          onProgress(progress / 100.0);
        });
      }
      try {
        final mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );

        if (isCancelled?.call() ?? false) {
          await VideoCompress.cancelCompression();
          throw Exception('تم إلغاء ضغط الفيديو');
        }

        if (mediaInfo == null || mediaInfo.file == null) {
          throw Exception('تعذر ضغط الفيديو');
        }

        final compressedFile = mediaInfo.file!;
        final length = await compressedFile.length();
        return PickedFile(
          path: compressedFile.path,
          name: file.name,
          size: length,
          mime: 'video/mp4',
        );
      } finally {
        subscription?.unsubscribe();
      }
    }

    return file;
  }
}
