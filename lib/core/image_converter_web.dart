import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web implementation using HTML Canvas to convert images (like HEIC on Safari iOS)
/// to standard JPEG format, ensuring it has valid magic bytes before uploading.
Future<({Uint8List bytes, String fileName, String mimeType})> convertImageIfNeed({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final lowerMime = mimeType.toLowerCase();
    final isHeic = lowerMime.contains('heic') || 
                   lowerMime.contains('heif') || 
                   fileName.toLowerCase().endsWith('.heic') ||
                   fileName.toLowerCase().endsWith('.heif');

    // Nếu không phải HEIC và MIME type đã hợp lệ (jpeg, png, webp, gif), không cần convert
    if (!isHeic && (
        lowerMime == 'image/jpeg' || 
        lowerMime == 'image/png' || 
        lowerMime == 'image/webp' || 
        lowerMime == 'image/gif')) {
      return (bytes: bytes, fileName: fileName, mimeType: mimeType);
    }

    debugPrint('[IMG-DBG] Web Image Converter: Converting $mimeType ($fileName) to image/jpeg...');

    // 1. Tạo Blob từ bytes
    final blob = html.Blob([bytes], mimeType);
    
    // 2. Tạo Object URL
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 3. Load image element
    final img = html.ImageElement();
    img.src = url;
    
    final completer = Completer<void>();
    StreamSubscription? loadSub;
    StreamSubscription? errorSub;
    
    loadSub = img.onLoad.listen((_) {
      completer.complete();
    });
    
    errorSub = img.onError.listen((err) {
      completer.completeError(Exception('Trình duyệt không thể decode file ảnh này.'));
    });
    
    try {
      // Chờ ảnh load xong
      await completer.future;
    } finally {
      await loadSub.cancel();
      await errorSub.cancel();
    }
    
    // 4. Tạo Canvas và vẽ ảnh lên đó
    final canvas = html.CanvasElement();
    
    // Giữ nguyên kích thước ảnh gốc hoặc scale nhẹ nếu quá lớn
    int width = img.naturalWidth;
    int height = img.naturalHeight;
    
    // Giới hạn max width/height ở web là 1280 để an toàn và tối ưu dung lượng
    const maxDimension = 1280;
    if (width > maxDimension || height > maxDimension) {
      if (width > height) {
        height = (height * maxDimension / width).round();
        width = maxDimension;
      } else {
        width = (width * maxDimension / height).round();
        height = maxDimension;
      }
    }
    
    canvas.width = width;
    canvas.height = height;
    
    final ctx = canvas.context2D;
    ctx.drawImageScaled(img, 0, 0, width, height);
    
    // 5. Export canvas sang JPEG base64 (85% chất lượng)
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final base64String = dataUrl.split(',').last;
    final resultBytes = base64.decode(base64String);
    
    // Giải phóng URL
    html.Url.revokeObjectUrl(url);
    
    // Đổi tên file đích sang đuôi .jpg
    String newFileName = fileName;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex >= 0) {
      newFileName = '${fileName.substring(0, dotIndex)}.jpg';
    } else {
      newFileName = '$fileName.jpg';
    }
    
    debugPrint(
      '[IMG-DBG] Web Image Converter Success: '
      'Converted to image/jpeg, size: ${resultBytes.length} bytes, new name: $newFileName',
    );
    
    return (
      bytes: resultBytes, 
      fileName: newFileName, 
      mimeType: 'image/jpeg'
    );
  } catch (e) {
    debugPrint('[IMG-DBG] Web Image Converter Failed: $e. Fallback to original file.');
    // Nếu có lỗi xảy ra, trả về file gốc để cố gắng upload tiếp
    return (bytes: bytes, fileName: fileName, mimeType: mimeType);
  }
}
