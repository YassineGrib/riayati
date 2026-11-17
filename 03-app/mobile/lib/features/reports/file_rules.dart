class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.mime,
  });

  final String path;
  final String name;
  final int size;
  final String mime;
}

class FileRules {
  static const int maxFiles = 5;
  static const int maxBytesPerFile = 30 * 1024 * 1024; // 30 MB

  static const Set<String> allowedMimes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/quicktime',
    'application/pdf',
  };

  static String? check(List<PickedFile> existing, PickedFile candidate) {
    if (existing.length >= maxFiles) {
      return 'الحد الأقصى للمرفقات هو $maxFiles ملفات.';
    }
    if (candidate.size > maxBytesPerFile) {
      return 'حجم الملف يتجاوز الحد الأقصى (30 ميغابايت).';
    }
    final normalizedMime = candidate.mime.toLowerCase().split(';').first.trim();
    if (!allowedMimes.contains(normalizedMime)) {
      return 'نوع الملف غير مدعوم. الأنواع المسموحة: صور (JPEG, PNG, WebP)، فيديو (MP4, MOV)، ومستندات PDF.';
    }
    return null;
  }
}
