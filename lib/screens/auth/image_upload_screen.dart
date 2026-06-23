import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../core/image_converter.dart';
import '../../core/mime_detector.dart';
import 'package:http/http.dart' as http_client;
import '../../services/auth_service.dart';
import '../../services/onboarding_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final List<XFile?> _images = List.generate(6, (index) => null);
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String get _baseUrl => AuthService.resolveBaseUrl();

  void _showSkipWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bỏ qua ảnh?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn sẽ không thể sử dụng tính năng khám phá và kết đôi nếu không có ảnh đại diện. Bạn có chắc muốn bỏ qua?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Quay lại thêm ảnh',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              OnboardingRouter.navigateToNextStep(context);
            },
            child: Text(
              'Bỏ qua',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImagesAndContinue() async {
    final validImages = _images.where((img) => img != null).toList();

    if (validImages.isEmpty) {
      _showSkipWarning();
      return;
    }

    setState(() => _isUploading = true);
    List<String> uploadedUrls = [];

    try {
      final token = await AuthService().getToken();

      for (var img in validImages) {
        String fileName = img!.name;
        final bytes = await img.readAsBytes();

        // Trên web, image_picker trả XFile không có extension
        // → dùng magic bytes để detect MIME type chính xác
        final String initialMimeType;
        String initialFileName = fileName;
        if (MimeDetector.hasValidExtension(initialFileName)) {
          final ext = initialFileName.split('.').last.toLowerCase();
          initialMimeType = ext == 'png'
              ? 'image/png'
              : (ext == 'webp'
                    ? 'image/webp'
                    : (ext == 'gif' ? 'image/gif' : 'image/jpeg'));
        } else {
          final detected = MimeDetector.detect(bytes);
          initialMimeType = detected.mimeType;
          initialFileName = MimeDetector.ensureExtension(initialFileName, detected.extension);
        }

        // Chuyển đổi định dạng ảnh nếu chạy trên Web (ví dụ HEIC -> JPEG)
        final converted = await convertImageIfNeed(
          bytes: bytes,
          fileName: initialFileName,
          mimeType: initialMimeType,
        );

        final finalBytes = converted.bytes;
        final finalFileName = converted.fileName;
        final mimeType = converted.mimeType;

        // Use the native http package MultipartRequest to upload files,
        // which avoids the Safari iOS type conversion InvalidAccessError Blob bug!
        final uri = Uri.parse('$_baseUrl/upload');
        final request = http_client.MultipartRequest('POST', uri);
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.files.add(
          http_client.MultipartFile.fromBytes(
            'file',
            finalBytes,
            filename: finalFileName,
            contentType: MediaType.parse(mimeType),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http_client.Response.fromStream(
          streamedResponse,
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            uploadedUrls.add(responseData['data']['url']);
          }
        }
      }

      if (uploadedUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không có ảnh nào được tải lên thành công. Vui lòng thử lại.',
              ),
            ),
          );
        }
        return;
      }

      // Save photos to profile — server accepts both "images" and "photos"
      final token2 = await AuthService().getToken();
      final patchUri = Uri.parse('$_baseUrl/profile/me');
      final patchResponse = await http_client.patch(
        patchUri,
        headers: {
          'Content-Type': 'application/json',
          if (token2 != null) 'Authorization': 'Bearer $token2',
        },
        body: jsonEncode({"images": uploadedUrls}),
      );

      if (patchResponse.statusCode < 200 || patchResponse.statusCode >= 300) {
        throw Exception(
          "Không thể cập nhật ảnh vào hồ sơ (Mã lỗi: ${patchResponse.statusCode})",
        );
      }

      if (mounted) {
        await OnboardingRouter.navigateToNextStep(context);
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi tải ảnh lên. Vui lòng thử lại.'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _uploadImagesAndContinue,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _images[index] = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        _showPhotoPermissionDialog();
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
    });
  }

  void _showPhotoPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Quyền truy cập ảnh',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bondy cần quyền truy cập thư viện ảnh để bạn có thể tải lên ảnh của mình. Vui lòng cấp quyền trong Cài đặt.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Mở Cài đặt',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int index, bool isProfile) {
    final XFile? image = _images[index];
    final bool isEmpty = image == null;

    return GestureDetector(
      onTap: () => isEmpty ? _pickImage(index) : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isEmpty
                  ? BondyColors.primaryLight.withValues(alpha: 0.3)
                  : BondyColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEmpty ? BondyColors.divider : BondyColors.primary,
                width: isEmpty ? 1 : 2,
              ),
            ),
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: isProfile
                              ? BondyColors.primary
                              : BondyColors.textHint,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isProfile ? 'Ảnh đại diện' : 'Thêm ảnh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isProfile
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isProfile
                                ? BondyColors.primary
                                : BondyColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: kIsWeb
                        ? Image.network(
                            image.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
          ),
          if (!isEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          /* if (isProfile && isEmpty)
             Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BondyColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '*Bắt buộc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
             ) */
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Thêm ảnh của bạn',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm ít nhất 1 ảnh đại diện và 2 ảnh giới thiệu để mọi người hiểu thêm về bạn nhé.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                  children: [
                    _buildPhotoSlot(0, true),
                    for (int i = 1; i < 6; i++) _buildPhotoSlot(i, false),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_images.where((img) => img != null).length}/6 ảnh',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : BondyButton(
                      text: 'Tiếp tục',
                      onPressed: _uploadImagesAndContinue,
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
