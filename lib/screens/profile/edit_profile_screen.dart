import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/bondy_error_mapper.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../widgets/location/shopee_location_picker.dart';
import '../../widgets/profile/prompts_editor_section.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ── Services ───────────────────────────────────────────────────────────────
  final _profileService = ProfileService();
  final _picker = ImagePicker();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoadingData = true;   // đang fetch dữ liệu từ server
  bool _isSaving = false;       // đang lưu
  String? _errorMessage;

  UserProfileModel? _profile;

  // Ảnh: kết hợp URL server + ảnh mới chọn từ máy
  // Index 0-5; giá trị là String (URL) hoặc XFile (local)
  final List<dynamic> _imageSlots = List.generate(6, (_) => null);

  // Controllers cho text fields
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _fullNameController;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _fullNameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.getProfile();
      _applyProfile(profile);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = BondyErrorMapper.message(e));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  /// Đổ dữ liệu profile vào state + controllers
  void _applyProfile(UserProfileModel profile) {
    setState(() {
      _profile = profile;
      _fullNameController.text = profile.fullName ?? profile.name ?? '';
      _bioController.text = profile.bio ?? '';
      _cityController.text = profile.city ?? '';

      // Map ảnh URL vào slots
      for (int i = 0; i < 6; i++) {
        _imageSlots[i] = i < profile.photos.length ? profile.photos[i] : null;
      }
    });
  }

  // ── Image picking ──────────────────────────────────────────────────────────
  Future<void> _pickImage(int index) async {
    // Tự động nén ảnh gốc xuống tối đa 1080p và 70% chất lượng để tiết kiệm tài nguyên
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (image != null && mounted) {
      setState(() => _imageSlots[index] = image);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageSlots[index] = null);
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      // 1. Phân loại ảnh: Ảnh cũ (String URL) và Ảnh mới (XFile)
      List<String> finalPhotos = [];
      List<XFile> newPhotos = [];
      
      for (var slot in _imageSlots) {
        if (slot is String) {
          finalPhotos.add(slot);
        } else if (slot is XFile) {
          newPhotos.add(slot);
        }
      }

      // 2. Upload các ảnh mới lần lượt lên server
      for (var file in newPhotos) {
        final uploadedUrl = await _profileService.uploadImage(file);
        if (uploadedUrl != null) {
          finalPhotos.add(uploadedUrl);
        } else {
          throw Exception("Không thể tải lên một số ảnh mới.");
        }
      }

      // 3. Gửi toàn bộ dữ liệu kèm bộ link ảnh tổng hợp lên /profile/me
      final fullName = _fullNameController.text.trim();
      await _profileService.updateProfile(
        fullName: fullName.isNotEmpty ? fullName : null,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        photos: finalPhotos.isNotEmpty ? finalPhotos : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hồ sơ đã được cập nhật ✓',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true); // trả true → caller biết đã lưu
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Chỉnh sửa hồ sơ',
        style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
      ),
      actions: [
        if (_isLoadingData)
          const SizedBox.shrink()
        else if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: Text(
              'Lưu',
              style: GoogleFonts.plusJakartaSans(
                  color: BondyColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ShopeeLocationPicker(
            onSelected: (addr, lat, lng) {
              setState(() {
                _cityController.text = addr;
              });
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 18, color: BondyColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _cityController.text.isEmpty ? 'Chọn địa chỉ...' : _cityController.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _cityController.text.isEmpty ? BondyColors.textHint : Colors.black87,
                  fontWeight: _cityController.text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  Widget _buildBody() {
    // ── Loading state ────────────────────────────────────────────────────────
    if (_isLoadingData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: BondyColors.primary),
            const SizedBox(height: 16),
            Text('Đang tải hồ sơ...',
                style: GoogleFonts.plusJakartaSans(
                    color: BondyColors.textSecondary)),
          ],
        ),
      );
    }

    // ── Error state ──────────────────────────────────────────────────────────
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: Color(0xFFD1D5DB)),
              const SizedBox(height: 16),
              Text('Không thể tải hồ sơ',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                    color: BondyColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: Text('Thử lại',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: BondyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    // ── Content ──────────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 28),
          _buildPhotosSection(),
          const SizedBox(height: 28),
          _buildFieldSection(
            title: 'Tên hiển thị',
            icon: Icons.person_outline,
            child: _buildTextField(
              controller: _fullNameController,
              hint: 'Tên của bạn...',
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldSection(
            title: 'Giới thiệu bản thân',
            child: _buildTextField(
              controller: _bioController,
              hint: 'Chia sẻ đôi chút về bạn...',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldSection(
            title: 'Địa chỉ của tôi',
            icon: Icons.location_on_outlined,
            child: _buildLocationSelector(),
          ),
          const SizedBox(height: 24),
          const PromptsEditorSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Profile header (avatar + tên + email) ──────────────────────────────────
  Widget _buildProfileHeader() {
    final profile = _profile;
    final displayName = profile?.displayName ?? '...';
    final email = profile?.email ?? '';
    final avatarUrl =
        profile?.image ?? (profile?.photos.isNotEmpty == true ? profile!.photos.first : null);

    return Row(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: BondyColors.primaryGradient,
          ),
          child: avatarUrl != null
              ? ClipOval(
                  child: Image.network(avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _avatarPlaceholder(displayName)),
                )
              : _avatarPlaceholder(displayName),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: BondyColors.textSecondary),
              ),
              if (profile?.gender != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BondyColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    profile!.gender!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BondyColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(initial,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  // ── Photos section ─────────────────────────────────────────────────────────
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Ảnh của bạn', icon: Icons.photo_library_outlined),
            const Spacer(),
            Text(
              '${_imageSlots.where((s) => s != null).length}/6',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: BondyColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ảnh đầu tiên sẽ là ảnh đại diện của bạn',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: BondyColors.textHint),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: 6,
          itemBuilder: (context, i) => _buildImageSlot(i),
        ),
      ],
    );
  }

  Widget _buildImageSlot(int index) {
    final slot = _imageSlots[index];
    final bool hasImage = slot != null;

    ImageProvider? imageProvider;
    if (slot is String) {
      imageProvider = NetworkImage(slot);
    } else if (slot is XFile) {
      if (kIsWeb) {
        imageProvider = NetworkImage(slot.path);
      } else {
        imageProvider = FileImage(File(slot.path));
      }
    }

    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? BondyColors.primary.withValues(alpha: 0.4) : const Color(0xFFE5E7EB),
            width: hasImage ? 1.5 : 1,
          ),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  if (index == 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BondyColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('⭐ Chính',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  // Nút xóa
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              )
            : _buildEmptySlot(index),
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    final isFirst = index == 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst
              ? BondyColors.primary.withValues(alpha: 0.5)
              : BondyColors.divider,
          width: 1.5,
          // Dashed border simulated via decoration
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFirst
                    ? BondyColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFirst ? Icons.add_a_photo : Icons.camera_alt_outlined,
                color: isFirst ? BondyColors.primary : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFirst ? 'Thêm ảnh đầu tiên' : 'Thêm ảnh',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: isFirst ? BondyColors.primary : const Color(0xFF9CA3AF),
                fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Field section wrapper ──────────────────────────────────────────────────
  Widget _buildFieldSection({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, icon: icon),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: BondyColors.primary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: BondyColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.plusJakartaSans(color: BondyColors.textHint, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BondyColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
