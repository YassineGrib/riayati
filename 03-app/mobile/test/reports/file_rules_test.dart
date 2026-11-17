import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/features/reports/file_rules.dart';

void main() {
  group('FileRules', () {
    const validFile1 = PickedFile(
      path: '/tmp/doc.pdf',
      name: 'doc.pdf',
      size: 1024 * 1024,
      mime: 'application/pdf',
    );
    const validFile2 = PickedFile(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      size: 5 * 1024 * 1024,
      mime: 'image/jpeg',
    );
    const validFile3 = PickedFile(
      path: '/tmp/photo.png',
      name: 'photo.png',
      size: 2 * 1024 * 1024,
      mime: 'image/png',
    );
    const validFile4 = PickedFile(
      path: '/tmp/image.webp',
      name: 'image.webp',
      size: 1 * 1024 * 1024,
      mime: 'image/webp',
    );
    const validFile5 = PickedFile(
      path: '/tmp/video.mp4',
      name: 'video.mp4',
      size: 20 * 1024 * 1024,
      mime: 'video/mp4',
    );

    test('accepts valid file and valid mixes of supported types', () {
      final existing = <PickedFile>[validFile1, validFile2];
      expect(FileRules.check(existing, validFile3), isNull);
      expect(FileRules.check(existing, validFile4), isNull);
      expect(FileRules.check(existing, validFile5), isNull);

      const quicktimeVideo = PickedFile(
        path: '/tmp/video.mov',
        name: 'video.mov',
        size: 15 * 1024 * 1024,
        mime: 'video/quicktime',
      );
      expect(FileRules.check(existing, quicktimeVideo), isNull);
    });

    test('rejects 6th file when 5 files already exist', () {
      final existing = <PickedFile>[
        validFile1,
        validFile2,
        validFile3,
        validFile4,
        validFile5,
      ];
      const candidate = PickedFile(
        path: '/tmp/extra.pdf',
        name: 'extra.pdf',
        size: 1024,
        mime: 'application/pdf',
      );
      final error = FileRules.check(existing, candidate);
      expect(error, isNotNull);
      expect(error, contains('5'));
    });

    test('rejects file larger than 30 MB (e.g. 31 MB)', () {
      const largeFile = PickedFile(
        path: '/tmp/big.pdf',
        name: 'big.pdf',
        size: 31 * 1024 * 1024,
        mime: 'application/pdf',
      );
      final error = FileRules.check([], largeFile);
      expect(error, isNotNull);
      expect(error, contains('30'));
    });

    test('accepts file exactly 30 MB', () {
      const exactFile = PickedFile(
        path: '/tmp/exact.pdf',
        name: 'exact.pdf',
        size: 30 * 1024 * 1024,
        mime: 'application/pdf',
      );
      expect(FileRules.check([], exactFile), isNull);
    });

    test('rejects unsupported types like .zip', () {
      const zipFile = PickedFile(
        path: '/tmp/archive.zip',
        name: 'archive.zip',
        size: 1024,
        mime: 'application/zip',
      );
      final error = FileRules.check([], zipFile);
      expect(error, isNotNull);
    });
  });
}
