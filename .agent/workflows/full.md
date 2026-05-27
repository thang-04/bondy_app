---
description: Knowledge Base & Coding Guidelines for Bondy_App (Flutter MVVM)
---

# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-28
**Type:** Mobile Application (Flutter)

## OVERVIEW
Bondy_App is a mobile application built with Flutter, focusing on relationships, connections, and personal healing. It utilizes the MVVM (Model-View-ViewModel) architecture implemented via the `provider` package for state management.

## DIRECTORY STRUCTURE
```text
lib/
├── main.dart             # App entry point, routing, and MultiProvider setup
├── screens/              # UI screens organized by feature
│   ├── auth/             # Authentication & onboarding
│   ├── chat/             # Messaging and chatbot interfaces
│   ├── discover/         # Matching and profiles
│   ├── healing/          # Content hub and library
│   ├── home/             # Main navigation shell
│   ├── relationship/     # Relationship management & dashboard
│   ├── settings/         # Settings and premium features
│   ├── social/           # Social features like date suggestions
│   └── survey/           # Onboarding survey questionnaires
├── theme/                # Application theming (colors, typography, etc.)
│   └── app_theme.dart
├── viewmodels/           # State management and business logic (MVVM)
│   └── auth/
│       └── auth_viewmodel.dart
└── widgets/              # Reusable UI components (e.g., buttons, inputs)
    └── bondy_button.dart
```

## ARCHITECTURE & CONVENTIONS

### 1. MVVM STATE MANAGEMENT
*   **Thư viện (Package):** Sử dụng `provider`.
*   **Quy tắc:**
    *   **ViewModel:** Các class chứa logic form/nghiệp vụ phải kế thừa `ChangeNotifier` (VD: `class AuthViewModel extends ChangeNotifier`).
    *   **UI (View):** Lắng nghe thay đổi từ ViewModel bằng `context.watch<T>()` để tự động rebuild UI khi có thay đổi. Gọi hàm từ ViewModel bằng `context.read<T>()` hoặc thông qua interface UI.
    *   Khai báo Provider trong `main.dart` thông qua `MultiProvider`.

### 2. ROUTING (ĐIỀU HƯỚNG)
*   Sử dụng Named Routes tĩnh cơ bản của Flutter (`MaterialApp.routes`).
*   Các route mới tạo phải được khai báo tập trung tại `main.dart` (VD: `'/home': (context) => const MainShellScreen()`).

### 3. UI LÀM VIỆC & WIDGETS
*   Mọi component có thể tái sử dụng phải được đặt ở `lib/widgets`.
*   Sử dụng ngôn ngữ Tiếng Việt cho các comment và tương tác giải thích code.
*   Theming (Màu sắc, Font chữ) được quản lý tập trung qua thư mục `lib/theme/app_theme.dart`. Khuyến khích sử dụng hằng số Theme có sẵn.

### 4. QUY TẮC PHÁT TRIỂN
*   **Chia nhỏ Widget:** Không viết toàn bộ màn hình vào một Widget. Trích xuất ra thành các hàm trả về Widget nhỏ hơn hoặc các Stateless/Stateful Widget riêng biệt.
*   **Ngôn ngữ giải thích:** Luôn sử dụng Tiếng Việt để đồng nhất.
*   Tránh để lọt trực tiếp logic kết nối Service bên trong UI code; hãy uỷ thác cho các ViewModel.
