import 'dart:typed_data';

/// Phát hiện MIME type từ magic bytes (file signature) của file.
///
/// Trên **web**, `image_picker` trả về `XFile` với tên dạng
/// `image_picker_web_xxxxx` (KHÔNG có extension), khiến việc dựa vào extension
/// để xác định MIME type bị sai → server reject "File không hợp lệ".
///
/// Hàm này đọc vài byte đầu tiên của file (magic bytes / file signature)
/// để xác định chính xác loại file bất kể filename có extension hay không.
class MimeDetector {
  /// Trả về `{mimeType, extension}` dựa trên magic bytes.
  /// Nếu không nhận diện được, fallback `application/octet-stream` + `bin`.
  static ({String mimeType, String extension}) detect(Uint8List bytes) {
    if (bytes.length < 4) {
      return (mimeType: 'application/octet-stream', extension: 'bin');
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return (mimeType: 'image/jpeg', extension: 'jpg');
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return (mimeType: 'image/png', extension: 'png');
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return (mimeType: 'image/gif', extension: 'gif');
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (mimeType: 'image/webp', extension: 'webp');
    }

    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return (mimeType: 'image/bmp', extension: 'bmp');
    }

    // HEIF/HEIC: check for 'ftyp' box at offset 4
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 && // f
        bytes[5] == 0x74 && // t
        bytes[6] == 0x79 && // y
        bytes[7] == 0x70) {
      // p
      // Check brand: heic, heix, hevc, mif1
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (brand.startsWith('hei') || brand == 'mif1') {
        return (mimeType: 'image/heic', extension: 'heic');
      }
    }

    // --- Audio ---
    // MP3: ID3 tag hoặc MPEG sync
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return (mimeType: 'audio/mpeg', extension: 'mp3');
    }
    // MP3 sync word
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return (mimeType: 'audio/mpeg', extension: 'mp3');
    }

    // OGG: OggS
    if (bytes.length >= 4 &&
        bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53) {
      return (mimeType: 'audio/ogg', extension: 'ogg');
    }

    // WebM: 1A 45 DF A3 (EBML header, cũng dùng cho MKV)
    if (bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return (mimeType: 'audio/webm', extension: 'webm');
    }

    // M4A/AAC in MPEG-4 container: ftyp box
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (brand == 'M4A ' || brand == 'isom' || brand == 'mp42') {
        return (mimeType: 'audio/m4a', extension: 'm4a');
      }
    }

    return (mimeType: 'application/octet-stream', extension: 'bin');
  }

  /// Kiểm tra xem filename có extension hợp lệ (image/audio) không.
  static bool hasValidExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return false;
    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return _knownExtensions.contains(ext);
  }

  /// Nếu filename không có extension hợp lệ, thêm extension phù hợp.
  static String ensureExtension(String fileName, String fallbackExt) {
    if (hasValidExtension(fileName)) return fileName;
    return '$fileName.$fallbackExt';
  }

  static const _knownExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'm4a',
    'mp3',
    'aac',
    'webm',
    'ogg',
  };
}
