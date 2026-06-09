import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Rewrite URL ảnh/audio đã lưu DB sang host hiện tại của API client.
///
/// Lý do: server `/api/upload` build URL từ `req.headers.host` rồi lưu cả
/// `http://10.0.2.2:3000/uploads/...` vào DB. Khi user upload ở emulator rồi
/// chuyển sang máy thật (qua LAN/adb reverse), URL cũ không reach được nên
/// ảnh không hiện. Hàm này thay host trong URL bằng host của baseUrl hiện tại,
/// giữ nguyên path. Trả về null nếu input null/rỗng.
///
/// Trên **web**, relative path `/uploads/...` được route qua API proxy
/// (`/api-proxy/uploads/...`) để Vercel forward request tới backend server,
/// tránh lỗi HTTPS certificate khi truy cập trực tiếp IP.
String? rewriteMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();

  // Nếu là relative path (bắt đầu bằng '/uploads', '/api/uploads', v.v.)
  // hoặc không phải URL tuyệt đối nhưng cũng không phải data/asset
  if (!trimmed.startsWith('http://') && 
      !trimmed.startsWith('https://') && 
      !trimmed.startsWith('data:') && 
      !trimmed.startsWith('asset')) {
    var path = trimmed;
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    
    try {
      final baseUrl = AuthService.resolveBaseUrl();

      // ── Web: route qua API proxy ──────────────────────────────────────
      // baseUrl trên web = "https://bondy-apk.vercel.app/api-proxy"
      // /uploads/user/file.jpg → .../api-proxy/uploads/user/file.jpg
      // Vercel rewrite: /api-proxy/* → http://server:3000/api/*
      // → backend serve file tại /api/uploads/user/file.jpg ✓
      if (kIsWeb) {
        final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
        final fullUrl = '$cleanBase$path';
        debugPrint('[IMG-DBG] relative path rewritten (web): $trimmed -> $fullUrl');
        return fullUrl;
      }

      // ── Native (mobile/desktop): dùng origin (scheme + host + port) ───
      final apiBase = Uri.parse(baseUrl);
      final origin = Uri(
        scheme: apiBase.scheme,
        host: apiBase.host,
        port: apiBase.hasPort ? apiBase.port : null,
      ).toString().replaceAll(RegExp(r'/+$'), '');
      
      final fullUrl = '$origin$path';
      debugPrint('[IMG-DBG] relative path rewritten: $trimmed -> $fullUrl');
      return fullUrl;
    } catch (_) {
      return trimmed;
    }
  }

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

  // ── Web: rewrite URL trỏ trực tiếp tới IP server ───────────────────
  // VD: https://103.149.86.25/api/uploads/... → .../api-proxy/uploads/...
  // Tránh lỗi self-signed cert / mixed content khi iOS Safari truy cập IP.
  if (kIsWeb) {
    final hostLower = parsed.host.toLowerCase();
    if (hostLower == '103.149.86.25') {
      final baseUrl = AuthService.resolveBaseUrl().replaceAll(RegExp(r'/+$'), '');
      // Server path: /api/uploads/... → strip /api → /uploads/...
      // vì baseUrl đã chứa /api-proxy (map tới /api trên backend)
      var serverPath = parsed.path;
      if (serverPath.startsWith('/api/')) {
        serverPath = serverPath.substring(4); // /api/uploads/... → /uploads/...
      } else if (serverPath.startsWith('/api')) {
        serverPath = serverPath.substring(4);
        if (serverPath.isNotEmpty && !serverPath.startsWith('/')) {
          serverPath = '/$serverPath';
        }
      }
      final fullUrl = '$baseUrl$serverPath';
      debugPrint('[IMG-DBG] IP URL rewritten (web): $trimmed -> $fullUrl');
      return fullUrl;
    }
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

  final rewritten = parsed
      .replace(
        scheme: apiBase.scheme,
        host: apiBase.host,
        port: apiBase.hasPort ? apiBase.port : null,
      )
      .toString();
      
  debugPrint('[IMG-DBG] dev host rewritten: $trimmed -> $rewritten');
  return rewritten;
}
