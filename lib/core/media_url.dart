import '../services/auth_service.dart';

/// Rewrite URL ảnh/audio đã lưu DB sang host hiện tại của API client.
///
/// Lý do: server `/api/upload` build URL từ `req.headers.host` rồi lưu cả
/// `http://10.0.2.2:3000/uploads/...` vào DB. Khi user upload ở emulator rồi
/// chuyển sang máy thật (qua LAN/adb reverse), URL cũ không reach được nên
/// ảnh không hiện. Hàm này thay host trong URL bằng host của baseUrl hiện tại,
/// giữ nguyên path. Trả về null nếu input null/rỗng.
String? rewriteMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();

  // Không động vào URL không phải http(s) (data:, asset paths, blob:, ...).
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return trimmed;
  }

  Uri? parsed;
  try {
    parsed = Uri.parse(trimmed);
  } catch (_) {
    return trimmed;
  }

  // Chỉ rewrite các host được biết là loopback/emulator/dev. Domain prod giữ
  // nguyên để không break ảnh đã host trên CDN/cloud.
  const devHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
  final hostLower = parsed.host.toLowerCase();
  final isLanIp = hostLower.startsWith('192.168.') ||
      hostLower.startsWith('10.') ||
      hostLower.startsWith('172.');
  if (!devHosts.contains(hostLower) && !isLanIp) return trimmed;

  // Lấy host:port hiện tại từ baseUrl, ghép lại với path/query/fragment cũ.
  final Uri apiBase;
  try {
    apiBase = Uri.parse(AuthService.resolveBaseUrl());
  } catch (_) {
    return trimmed;
  }

  return parsed
      .replace(
        scheme: apiBase.scheme,
        host: apiBase.host,
        port: apiBase.hasPort ? apiBase.port : null,
      )
      .toString();
}
