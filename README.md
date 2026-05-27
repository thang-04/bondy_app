<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge" alt="Version" />
</p>

<h1 align="center">Bondy App</h1>
<p align="center">
  <strong>Ứng dụng hẹn hò và chữa lành cảm xúc</strong><br/>
  Kết nối con người qua sự thấu hiểu và hỗ trợ mối quan hệ lành mạnh
</p>

---

## 📋 Mục lục

- [Tổng quan](#-tổng-quan)
- [Định vị chiến lược](#-định-vị-chiến-lược)
- [Giá trị cốt lõi](#-giá-trị-cốt-lõi)
- [Tech Stack](#-tech-stack)
- [Kiến trúc](#-kiến-trúc)
- [Luồng ứng dụng](#-luồng-ứng-dụng)
- [Cài đặt & Chạy](#-cài-đặt--chạy)
- [Quy trình phát triển](#-quy-trình-phát-triển)
- [Coding Standards](#-coding-standards)
- [Tham khảo](#-tham-khảo)

---

## 📌 Tổng quan

**Bondy** là ứng dụng mobile cross-platform (Flutter) tập trung vào hẹn hò và chữa lành cảm xúc. Sản phẩm hỗ trợ người dùng qua 4 nhóm tính năng chính:

| Tính năng | Mô tả |
|-----------|-------|
| **Kết đôi** | Discovery kiểu swipe, xem profile chi tiết, chế độ Softened |
| **Hỏi Bondy** | Chatbot AI tư vấn tâm lý, gợi ý hành trình chữa lành |
| **Mối quan hệ** | Dashboard cặp đôi, check-in cảm xúc, công cụ giải quyết mâu thuẫn, cột mốc |
| **Healing** | Thư viện nội dung: bài viết, audio, thiền định |

**Thông tin kỹ thuật:** Dart ^3.11.0 · Flutter · Material Design 3 · UI tiếng Việt

---

## 🧠 Định vị chiến lược

| App hẹn hò khác | Bondy |
|-----------------|-------|
| Tập trung **Match** | Tập trung **Chất lượng mối quan hệ** |
| Swipe là trung tâm | **Emotional journey** là trung tâm |
| Không hỗ trợ sau khi yêu | **Đồng hành** sau khi yêu |

---

## 💎 Giá trị cốt lõi

> **Tinder bán:** *"Find someone."*  
>  
> **Bondy bán:** *"Know what to do next in love."*

Bondy không chỉ giúp bạn tìm người — Bondy giúp bạn biết **phải làm gì tiếp theo** trong tình yêu, từ gặp gỡ, yêu thương đến chữa lành và lớn lên cùng nhau.

---

## 🛠 Tech Stack

| Layer | Công nghệ | Mục đích |
|-------|-----------|----------|
| Framework | Flutter | Cross-platform mobile |
| Language | Dart 3.11+ | Ngôn ngữ chính |
| State | Provider | State management (MVVM) |
| Routing | Named Routes | MaterialApp |
| Typography | google_fonts | Plus Jakarta Sans |
| UI | Material 3 | Theme & components |

---

## 🏗 Kiến trúc

### Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry, providers, routes
├── theme/
│   └── app_theme.dart           # BondyColors, BondyTheme
├── viewmodels/
│   └── auth/
│       └── auth_viewmodel.dart  # Auth validation, OTP flow
├── widgets/
│   ├── bondy_button.dart        # Shared button
│   └── bondy_logo.dart          # Logo components
└── screens/
    ├── auth/                    # Onboarding flow
    ├── survey/                  # 9-question survey
    ├── home/                    # Main shell, bottom nav
    ├── discover/                # Matching, profiles
    ├── chat/                    # 1:1 chat, chatbot
    ├── healing/                 # Content library
    ├── social/                  # Date suggestions
    ├── relationship/            # Couple tools
    └── settings/                # Premium paywall
```

### Sơ đồ luồng tổng quan

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Welcome   │────▶│  Sign Up     │────▶│    OTP      │
└─────────────┘     │  (Phone)     │     │  Verify     │
                    └──────────────┘     └──────┬──────┘
                                                │
                    ┌───────────────────────────▼───────────────────────┐
                    │              Profile Setup → Survey (Q1–Q9)        │
                    └───────────────────────────┬───────────────────────┘
                                                │
┌───────────────────────────────────────────────▼───────────────────────────────────┐
│                              Main Shell (Bottom Nav)                               │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐               │
│  │  Home   │  │ Healing │  │ MATCH ★  │  │Community│  │ Profile  │               │
│  └─────────┘  └─────────┘  └────┬─────┘  └─────────┘  └──────────┘               │
│       │             │            │              │             │                    │
│       ▼             ▼            ▼              ▼             ▼                    │
│  Content    Content Hub    Discover    Matches / Chat   Relationship              │
│  Chatbot    Library        Profiles    Healing Chat     Premium                   │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### State Management

- **Provider** với mô hình gần **MVVM**
- `AuthViewModel`: validation SĐT, điều hướng OTP
- Mở rộng: tạo ViewModel mới → đăng ký trong `MultiProvider` tại `main.dart`

---

## 🔄 Luồng ứng dụng

### Onboarding

```
Welcome → Sign Up (SĐT) → OTP → Profile Setup → Survey Intro → Q1→Q9 → Result → Home
```

### Main App

| Khu vực | Màn hình / Hành động |
|---------|----------------------|
| **Main Shell** | Home \| Healing \| MATCH \| Community \| Profile |
| **Từ Home** | Hỏi Bondy, Bắt đầu hành trình, Kết đôi, Mối quan hệ, Premium |
| **Discover** | Swipe matching → Profile chi tiết → Softened mode |
| **Chat** | Matches list → Chat 1:1 hoặc Healing chatbot |
| **Relationship** | Dashboard → Check-in, Conflict tool, Milestones, Invite partner |

### Routing (Named Routes)

| Route | Screen |
|-------|--------|
| `/` | WelcomeScreen |
| `/sign-up`, `/otp`, `/profile-setup` | Auth flow |
| `/survey/intro` … `/survey/q9`, `/survey/result` | Survey flow |
| `/home` | MainShellScreen |
| `/discover`, `/discover/softened`, `/profile-detail` | Discovery |
| `/matches`, `/chat`, `/chatbot`, `/chat/deeper` | Chat |
| `/content`, `/date-suggestions` | Content & Social |
| `/relationship/*` | Relationship tools |
| `/settings/premium` | Premium paywall |

---

## 🚀 Cài đặt & Chạy

### Yêu cầu

- **Flutter** SDK ^3.11.0  
- **Android Studio** hoặc **VS Code** + Flutter plugin  
- **Xcode** (macOS) cho iOS hoặc Android emulator / thiết bị

### Quick Start

```bash
git clone <repository-url>
cd Bondy_App

flutter pub get
flutter run
```

### Build Release

```bash
flutter build apk        # Android
flutter build ios        # iOS (macOS)
flutter build apk --release
```

### Kiểm tra môi trường

```bash
flutter doctor -v
```

---

## 📐 Quy trình phát triển

---

## ✍️ Coding Standards

| Hạng mục | Quy định |
|----------|----------|
| **Đặt tên Screen** | `<Tên>Screen` (vd: `WelcomeScreen`) |
| **Đặt tên ViewModel** | `<Feature>ViewModel` |
| **Shared Widgets** | Prefix `Bondy` (vd: `BondyButton`) |
| **Thư mục** | snake_case (vd: `profile_setup_screen.dart`) |
| **Theme** | Dùng `BondyColors`, tránh hardcode màu |

### Thêm màn hình mới

1. Tạo `screens/<feature>/<tên>_screen.dart`
2. Khai báo route trong `main.dart`
3. Dùng `BondyButton`, `BondyLogo` khi phù hợp

### Tổ chức import

```
1. Flutter / packages
2. Theme
3. ViewModels
4. Screens (theo nhóm feature)
```

<p align="center"><sub>Bondy App · Team Documentation</sub></p>
