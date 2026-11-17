import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/features/reports/attachment_compressor.dart';
import 'package:riayati/features/reports/file_rules.dart';

void main() {
  group('AttachmentCompressor', () {
    test('fake compressor compresses image reducing size', () async {
      final compressor = FakeAttachmentCompressor(compressFactor: 0.4);
      const original = PickedFile(
        path: '/tmp/original.png',
        name: 'original.png',
        size: 10 * 1024 * 1024,
        mime: 'image/png',
      );

      double? progressValue;
      final compressed = await compressor.compress(
        original,
        onProgress: (p) => progressValue = p,
      );

      expect(compressed.size, 4 * 1024 * 1024);
      expect(compressed.path, contains('.compressed'));
      expect(progressValue, 1.0);
      expect(compressor.compressCalls, 1);
    });

    test('fake compressor leaves PDF uncompressed', () async {
      final compressor = FakeAttachmentCompressor();
      const pdf = PickedFile(
        path: '/tmp/doc.pdf',
        name: 'doc.pdf',
        size: 5 * 1024 * 1024,
        mime: 'application/pdf',
      );

      final result = await compressor.compress(pdf);
      expect(result.size, pdf.size);
      expect(result.path, pdf.path);
    });

    test('fake compressor throws on failure', () async {
      final compressor = FakeAttachmentCompressor(shouldFail: true);
      const video = PickedFile(
        path: '/tmp/video.mp4',
        name: 'video.mp4',
        size: 15 * 1024 * 1024,
        mime: 'video/mp4',
      );

      expect(() => compressor.compress(video), throwsException);
    });

    test('fake compressor handles cancellation', () async {
      final compressor = FakeAttachmentCompressor(delay: const Duration(milliseconds: 10));
      const video = PickedFile(
        path: '/tmp/video.mp4',
        name: 'video.mp4',
        size: 15 * 1024 * 1024,
        mime: 'video/mp4',
      );

      var cancelled = false;
      final future = compressor.compress(
        video,
        isCancelled: () => cancelled,
      );
      cancelled = true;

      expect(future, throwsException);
    });

    test('FileRules applies to COMPRESSED size: file over 30MB compressed to under 30MB is accepted', () {
      const original = PickedFile(
        path: '/tmp/big.jpg',
        name: 'big.jpg',
        size: 35 * 1024 * 1024, // 35 MB
        mime: 'image/jpeg',
      );

      // Raw original would fail FileRules:
      expect(FileRules.check([], original), isNotNull);

      // Compressed size is 15 MB:
      const compressed = PickedFile(
        path: '/tmp/big.jpg.compressed',
        name: 'big.jpg',
        size: 15 * 1024 * 1024,
        mime: 'image/jpeg',
      );

      expect(FileRules.check([], compressed), isNull);
    });
  });
}
