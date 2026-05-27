# API Base URL Configuration via Environment Variables

## Status
Approved

## Problem
`AuthService.resolveBaseUrl()` hardcodes platform-specific URLs and does not read from `.env`. This causes:
- Android emulator works (`10.0.2.2:3000`)
- Real device fails (localhost unreachable)

## Solution
Use `flutter_dotenv` to load `API_BASE_URL` from `.env` at runtime.

## Behavior

| Environment      | Base URL                         |
|------------------|----------------------------------|
| Android Emulator  | `http://10.0.2.2:3000/api`        |
| Android Real Device (dev) | `http://<VPS_IP>:3000/api` |
| iOS Simulator     | `http://localhost:3000/api`       |
| Web (localhost)  | `http://localhost:3000/api`       |
| Production       | `http://api.bondy.vn/api` (or domain) |

## Implementation

### 1. Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

### 2. Environment Loading
In `main.dart` before `runApp()`:
```dart
await dotenv.load(fileName: '.env');
```

### 3. resolveBaseUrl() Logic
Update `auth_service.dart`:
```dart
static String resolveBaseUrl({String? baseUrlOverride}) {
  if (baseUrlOverride != null && baseUrlOverride.trim().isNotEmpty) {
    return baseUrlOverride.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  // Priority 1: .env file (for real device and production)
  final envUrl = dotenv.env['API_BASE_URL'];
  if (envUrl != null && envUrl.trim().isNotEmpty) {
    return envUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  // Priority 2: Platform-specific fallback
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';  // Android emulator only
  }
  return 'http://localhost:3000/api';
}
```

### 4. Current .env Configuration
```
# API Configuration
API_BASE_URL=http://192.168.4.23:3000
```

## Files Affected
- `Bondy_App/pubspec.yaml`
- `Bondy_App/lib/main.dart`
- `Bondy_App/lib/services/auth_service.dart`
- `Bondy_App/.env`

## Deployment Flow
1. **Development (real device)**: Set `API_BASE_URL=http://<dev-machine-ip>:3000` in `.env`
2. **Production**: Set `API_BASE_URL=http://api.bondy.vn` (or VPS IP) before deploy
3. **Emulator**: Uses fallback `10.0.2.2:3000` when `.env` not configured

## Verification
After implementation:
1. Build APK with real device connected - should hit correct IP
2. Build APK on emulator - should use `10.0.2.2:3000`
3. Change `.env` IP - app should respect new value on next restart