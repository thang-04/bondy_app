import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bondy/core/mime_detector.dart';

void main() {
  group('MimeDetector Tests', () {
    test('Detect JPEG from magic bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final result = MimeDetector.detect(bytes);
      expect(result.mimeType, 'image/jpeg');
      expect(result.extension, 'jpg');
    });

    test('Detect PNG from magic bytes', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final result = MimeDetector.detect(bytes);
      expect(result.mimeType, 'image/png');
      expect(result.extension, 'png');
    });

    test('Detect WebP from magic bytes', () {
      final bytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50  // WEBP
      ]);
      final result = MimeDetector.detect(bytes);
      expect(result.mimeType, 'image/webp');
      expect(result.extension, 'webp');
    });

    test('Detect GIF from magic bytes', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
      final result = MimeDetector.detect(bytes);
      expect(result.mimeType, 'image/gif');
      expect(result.extension, 'gif');
    });

    test('Fallback to octet-stream for unknown bytes', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      final result = MimeDetector.detect(bytes);
      expect(result.mimeType, 'application/octet-stream');
      expect(result.extension, 'bin');
    });

    test('hasValidExtension checks filenames correctly', () {
      expect(MimeDetector.hasValidExtension('photo.jpg'), isTrue);
      expect(MimeDetector.hasValidExtension('photo.JPEG'), isTrue);
      expect(MimeDetector.hasValidExtension('photo.png'), isTrue);
      expect(MimeDetector.hasValidExtension('photo.webp'), isTrue);
      expect(MimeDetector.hasValidExtension('audio.mp3'), isTrue);
      expect(MimeDetector.hasValidExtension('no_ext'), isFalse);
      expect(MimeDetector.hasValidExtension('invalid.ext'), isFalse);
      expect(MimeDetector.hasValidExtension('dotted.file.name.png'), isTrue);
    });

    test('ensureExtension appends if extension is invalid or missing', () {
      expect(MimeDetector.ensureExtension('photo.jpg', 'jpg'), 'photo.jpg');
      expect(MimeDetector.ensureExtension('photo', 'jpg'), 'photo.jpg');
      expect(MimeDetector.ensureExtension('photo.invalid', 'jpg'), 'photo.invalid.jpg');
    });
  });
}
