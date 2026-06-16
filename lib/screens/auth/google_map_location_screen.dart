import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location_display.dart';
import '../../services/onboarding_router.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class GoogleMapLocationScreen extends StatefulWidget {
  final bool isPicking;
  const GoogleMapLocationScreen({super.key, this.isPicking = false});

  @override
  State<GoogleMapLocationScreen> createState() =>
      _GoogleMapLocationScreenState();
}

class _GoogleMapLocationScreenState extends State<GoogleMapLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  static const LatLng _initialPosition = LatLng(10.762622, 106.660172);

  LatLng _currentPosition = _initialPosition;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _finishLocationLoad(
          'Vui lòng bật dịch vụ định vị hoặc tìm địa chỉ thủ công.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _finishLocationLoad(
          'Quyền truy cập vị trí bị từ chối. Bạn vẫn có thể tìm địa chỉ thủ công.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _finishLocationLoad(
          'Quyền vị trí bị từ chối vĩnh viễn. Hãy mở cài đặt hoặc tìm địa chỉ thủ công.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 12),
      );
      final target = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentPosition = target;
        _isLoading = false;
        _statusMessage = null;
      });
      _mapController.move(target, 16);
    } on TimeoutException {
      _finishLocationLoad(
        'Không lấy được GPS kịp thời. Hãy thử lại hoặc tìm địa chỉ thủ công.',
      );
    } catch (e) {
      debugPrint('Determine location error: $e');
      _finishLocationLoad(
        'Không thể lấy vị trí hiện tại. Hãy tìm địa chỉ thủ công.',
      );
    }
  }

  void _finishLocationLoad(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statusMessage = message;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchLocation(String address) async {
    final keyword = address.trim();
    if (keyword.isEmpty || _isSearching) return;

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(keyword);
      if (locations.isEmpty) {
        _showMessage('Không tìm thấy vị trí này.');
        return;
      }

      final location = locations.first;
      final target = LatLng(location.latitude, location.longitude);
      if (!mounted) return;
      setState(() {
        _currentPosition = target;
        _statusMessage = null;
      });
      _mapController.move(target, 16);
    } catch (e) {
      debugPrint('Error searching location: $e');
      _showMessage('Lỗi khi tìm kiếm vị trí. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vị trí của bạn',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.5,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _currentPosition = position.center;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.exe.bondy_app',
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildSearchBox(),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  _buildStatusBanner(_statusMessage!),
                ],
              ],
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                color: BondyColors.primary,
                size: 48,
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpCard(),
                const SizedBox(height: 16),
                BondyButton(
                  text: _isSaving ? 'Đang lưu...' : 'Xác nhận vị trí',
                  onPressed: _isSaving ? () {} : _handleSaveLocation,
                ),
              ],
            ),
          ),
          if (_isLoading || _isSaving)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm hoặc nhập địa chỉ...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: BondyColors.textHint,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: BondyColors.primary),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: _searchLocation,
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: BondyColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: BondyColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'GPS sẽ đưa bạn tới vị trí hiện tại. Kéo bản đồ hoặc tìm kiếm để chỉnh pin trước khi lưu.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: BondyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveLocation() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final address = await _resolveAddress();
    if (address == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(
        'Khong xac dinh duoc khu vuc. Hay tim hoac nhap ten quan/huyen, tinh/thanh.',
      );
      return;
    }

    if (widget.isPicking) {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, {
          'address': address,
          'lat': _currentPosition.latitude,
          'lng': _currentPosition.longitude,
        });
      }
      return;
    }

    try {
      await _profileService.updateLocation(
        city: address,
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      await OnboardingRouter.navigateToNextStep(context);
    } catch (e) {
      debugPrint('Save location error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Lỗi khi lưu vị trí. Vui lòng thử lại.');
    }
  }

  Future<String?> _resolveAddress() async {
    final manualAddress = _searchController.text.trim();
    try {
      final placemarks = await placemarkFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        for (final p in placemarks) {
          final readable = buildReadableLocationName(
            street: p.street,
            subLocality: p.subLocality,
            locality: p.locality,
            subAdministrativeArea: p.subAdministrativeArea,
            administrativeArea: p.administrativeArea,
          );
          if (readable != null) return readable;
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    return normalizeReadableLocation(manualAddress);
  }
}
