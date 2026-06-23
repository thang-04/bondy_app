import 'dart:typed_data';

/// Stub implementation for mobile/desktop platform (non-web).
/// Simply returns the original bytes and details without changes,
/// as native platforms handle HEIC conversion via image_picker directly.
Future<({Uint8List bytes, String fileName, String mimeType})> convertImageIfNeed({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  return (bytes: bytes, fileName: fileName, mimeType: mimeType);
}
