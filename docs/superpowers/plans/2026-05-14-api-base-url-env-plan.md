# API Base URL Environment Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Load `API_BASE_URL` from `.env` at runtime so real devices can connect to configurable server IP.

**Architecture:** Use `flutter_dotenv` package to load environment variables before app starts. `resolveBaseUrl()` checks env var first, falls back to platform-specific defaults.

**Tech Stack:** `flutter_dotenv: ^5.1.0`, Dart `.env` files

---

### Task 1: Add flutter_dotenv dependency

**Files:**
- Modify: `Bondy_App/pubspec.yaml`

- [ ] **Step 1: Add flutter_dotenv to pubspec.yaml**

In `Bondy_App/pubspec.yaml`, add under `dependencies` section (line 50 after flutter_secure_storage):

```yaml
flutter_dotenv: ^5.1.0
```

- [ ] **Step 2: Verify dependency**

Run: `cd Bondy_App && flutter pub get`
Expected: `flutter_dotenv` appears in dependencies

- [ ] **Step 3: Commit**

```bash
cd Bondy_App && git add pubspec.yaml && git commit -m "feat: add flutter_dotenv dependency"
```

---

### Task 2: Load .env in main.dart

**Files:**
- Modify: `Bondy_App/lib/main.dart:60-62`

- [ ] **Step 1: Add dotenv import and load**

In `Bondy_App/lib/main.dart`, add import after existing imports (after line 1):

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
```

Then modify the `main()` function (lines 60-62) to:

```dart
void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const BondyApp());
}
```

- [ ] **Step 2: Verify main.dart compiles**

Run: `cd Bondy_App && flutter analyze lib/main.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart && git commit -m "feat: load .env before app starts"
```

---

### Task 3: Update resolveBaseUrl() to read from env

**Files:**
- Modify: `Bondy_App/lib/services/auth_service.dart:119-128`

- [ ] **Step 1: Add dotenv import**

In `Bondy_App/lib/services/auth_service.dart`, add import at top (after existing imports):

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
```

- [ ] **Step 2: Update resolveBaseUrl() method**

Replace lines 119-128:

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

- [ ] **Step 3: Verify auth_service.dart compiles**

Run: `cd Bondy_App && flutter analyze lib/services/auth_service.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/services/auth_service.dart && git commit -m "feat: read API_BASE_URL from .env in resolveBaseUrl()"
```

---

### Task 4: Verify .env configuration

**Files:**
- Read: `Bondy_App/.env`

- [ ] **Step 1: Verify .env has API_BASE_URL**

Check `Bondy_App/.env` contains:
```
API_BASE_URL=http://192.168.4.23:3000
```

If not present, add it.

- [ ] **Step 2: Commit if changed**

```bash
git add .env && git commit -m "chore: set API_BASE_URL for real device testing"
```

---

## Verification Steps

After all tasks complete:

1. **Emulator test:** Start Android emulator, run app - should use `10.0.2.2:3000`
2. **Real device test:** Run on physical device - should use `192.168.4.23:3000`
3. **Change test:** Edit `.env` with different IP, restart app - should use new IP

## Notes

- `.env` file should NOT be committed to version control (add to `.gitignore` if needed)
- For production, set `API_BASE_URL` to actual VPS domain/IP before deploy
- The `flutter_dotenv` package loads variables at runtime, not build time