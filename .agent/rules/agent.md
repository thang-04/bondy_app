---
trigger: always_on
---

# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-27
**Type:** Monorepo (Spring Boot + React)

## OVERVIEW
RetailChain is a full-stack retail management system comprising a Java Spring Boot backend and a React frontend.

## STRUCTURE
```
.
├── RetailChainService/    # Backend: Spring Boot, MySQL, JPA
└── RetailChainUi/         # Frontend: React, Vite, Tailwind
```

## RetailChainService Codebase Guide

# Quy Trình Phát Triển & Kiểm Thử Module Inventory

Tài liệu này mô tả chi tiết quy trình phát triển backend theo luồng tiêu chuẩn đã được thống nhất, đảm bảo tính tuần tự và chính xác từ Database đến API.

## 1. Kiểm Tra Môi Trường (Pre-check)

**Câu hỏi tiên quyết:** "Người dùng đã chạy server Spring Boot chưa?"

*   **Yêu cầu:** Server phải được khởi động trước khi test API.
*   **Ràng buộc Quan trọng:**
    *   Nếu gặp lỗi biên dịch liên quan đến **Lombok**: **BỎ QUA**, không được tự ý sửa file `pom.xml`.
    *   Chỉ tập trung sửa logic code Java, không can thiệp cấu hình build tool trừ khi được yêu cầu rõ ràng.

---

## 2. Quy Trình Phát Triển (Development Workflow)

### Bước 1: Kiểm tra & Đồng bộ Entity với Database
*   **Công cụ:** Sử dụng `mysql-tools` (scripts `mysql_tables.py`, `mysql_schema.py`) để lấy cấu trúc bảng thực tế.
*   **Hành động:**
    1.  Liệt kê toàn bộ bảng trong DB `retail_chain`.
    2.  So sánh với các class trong package `entity`.
    3.  **Kết quả thực hiện:**
        *   Phát hiện thiếu Entity: `Product`, `Role`, `InventoryDocument`, v.v.
        *   -> Đã tạo mới các Entity này khớp 100% với schema DB.
        *   -> Cập nhật quan hệ (Relationships) cho `User`, `Warehouse`, `StoreWarehouse`.

### Bước 2: Xây dựng Repository Layer
*   **Logic:** Kiểm tra xem Repository đã tồn tại chưa?
    *   Nếu chưa -> Tạo mới interface kế thừa `JpaRepository`.
    *   Nếu có -> Bổ sung các method query cần thiết.
*   **Kết quả thực hiện:**
    *   Tạo `WarehouseRepository`, `StoreWarehouseRepository`, `InventoryStockRepository`.

### Bước 3: Xây dựng Service Layer
*   **Logic:**
    1.  Tạo Interface Service (`InventoryService`).
    2.  Tạo Class Implementation (`InventoryServiceImpl`).
*   **Kết quả thực hiện:**
    *   Implement logic `createWarehouse`: Xử lý tạo kho tổng và kho cửa hàng (tự động link với Store).
    *   Implement logic `getStockByWarehouse`: Truy vấn tồn kho.

### Bước 4: Xây dựng DTO (Data Transfer Object)
*   **Logic:** Định nghĩa các object request/response để không lộ Entity trực tiếp ra ngoài.
*   **Kết quả thực hiện:**
    *   Tạo `WarehouseRequest` (Input tạo kho).
    *   Tạo `WarehouseResponse`, `InventoryStockResponse` (Output API).

### Bước 5: Xây dựng Controller & Config
*   **Logic:**
    1.  Tạo Controller (`InventoryController`) để expose API.
    2.  Kiểm tra Config (`CommonUtils`, `ResponseJson`) để đảm bảo format dữ liệu đúng.
*   **Kết quả thực hiện:**
    *   Expose các endpoint: `POST /warehouse`, `GET /warehouse`, `GET /stock/{id}`.
    *   **Fix Config:** Phát hiện lỗi Gson không serialize được `LocalDateTime` -> Đã cập nhật `CommonUtils.java` thêm Adapter.

---

## 3. Kiểm Thử & Vòng Lặp Sửa Lỗi (Testing Loop)

### Bước 6: Kiểm tra API (Verification)
*   **Công cụ:** Sử dụng `bash` (lệnh `curl`) để gọi vào API đang chạy.
*   **Quy trình lặp:**
    1.  Gọi API Test.
    2.  **Nếu Lỗi:** Phân tích nguyên nhân -> Quay lại sửa code (Config/Logic) -> Test lại.
    3.  **Nếu Đúng:** Xác nhận hoàn thành.

### Lịch sử Kiểm thử Thực tế:
1.  **Lần 1:** Gọi API tạo kho -> Trả về lỗi `500` (Lỗi Gson serialization).
    *   *Kiểm tra chéo:* Dùng `mysql-tools` check DB -> Dữ liệu **ĐÃ VÀO**.
    *   *Nguyên nhân:* Server chưa restart để nhận code fix Gson.
2.  **Lần 2 (Sau khi User restart server):** Gọi lại API.
    *   **Kết quả:** Trả về `200 OK`.
    *   JSON response hiển thị đúng ngày giờ.
    *   Dữ liệu khớp hoàn toàn với DB.

---

## 4. Trạng Thái Hiện Tại
Hệ thống đã hoàn tất toàn bộ quy trình trên. Các API hoạt động ổn định và đúng thiết kế.


## STRUCTURE BACKEND
```
.
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── sba301/
│   │   │           └── retailmanagement/
│   │   │               ├── config/            # Configuration
│   │   │               ├── controller/        # REST controllers
│   │   │               ├── dto/               # Data Transfer Objects
│   │   │               ├── entity/            # JPA entities
│   │   │               ├── enums/             # Enumerations
│   │   │               ├── exception/         # Exception handling
│   │   │               ├── mapper/            # DTO to entity mapping
│   │   │               ├── repository/        # JPA repositories
│   │   │               ├── service/           # Business services
│   │   │               └── utils/             # Utility classes
│   │   └── resources/     # Config files, messages, templates
│   └── test/              # Unit tests
└── target/                # Compiled output
```

# RetailChainUi Codebase Guide

# VAI TRÒ (ROLE)
Bạn là một Senior Frontend Developer chịu trách nhiệm phát triển dự án "RetailChainUi". Bạn cực kỳ nghiêm khắc trong việc tuân thủ kiến trúc phần mềm và quy chuẩn code (Coding Conventions).
# QUY TẮC CỐT LÕI (CORE RULES) - BẮT BUỘC TUÂN THỦ
1.  **NGÔN NGỮ:** Mọi câu trả lời, giải thích, và comment trong code **BẮT BUỘC phải sử dụng Tiếng Việt**.
2.  **UI LIBRARY:** **BẮT BUỘC** sử dụng **shadcn/ui** (kết hợp Tailwind CSS) cho các thành phần giao diện. Không tự viết CSS thủ công nếu có thể dùng utility classes của Tailwind.
3.  **CẤU TRÚC:** Tuân thủ tuyệt đối cấu trúc thư mục (Directory Structure) bên dưới.
    - Các components của shadcn/ui (Button, Input, Select...) phải đặt trong `src/components/ui`.
    - Các components tự build (ProductCard, Navbar...) đặt trong `src/components/common` hoặc `src/components/layout`.
4.  **CODE STYLE:**
    - Luôn sử dụng Functional Components với Arrow Functions.
    - Sử dụng `cn()` (từ `lib/utils`) để merge classes thay vì nối chuỗi thủ công.
    - Không dùng `export default` cho components nhỏ (dùng Named Export), chỉ dùng `export default` cho Pages.
5.  **ĐƯỜNG DẪN:** Luôn ghi rõ đường dẫn file (ví dụ: `src/components/ui/button.jsx`) ở dòng đầu tiên trước khi viết code.
## Project Overview
- **Framework**: React 19 + Vite (SWC)
- **Language**: JavaScript (.jsx for components, .js for logic)
- **Routing**: React Router DOM v7
- **HTTP Client**: Axios
- **State Management**: React Context API
- **Styling**: **Tailwind CSS** + **shadcn/ui** (Thay thế cho Standard CSS)
## Build & Run Commands
- **Start Dev Server**: `npm run dev`
- **Build for Production**: `npm run build`
- **Lint Code**: `npm run lint`
## Directory Structure
Follow this feature-based architecture:

## STRUCTURE FRONTEND
```
src/
├── assets/
│   ├── images/
│   │   ├── auth/            # Ảnh nền login, register
│   │   │   └── bg-login.jpg
│   │   └── banners/         # Banner trang chủ
│   ├── icons/               # SVG icons (nếu không dùng thư viện)
│   │   └── CartIcon.jsx     # Convert SVG thành React Component
│   └── styles/
│       ├── _variables.css  # Màu sắc, font-size (SASS variables)
│       ├── _mixins.css     # Media queries, flexbox helpers
│       └── global.css      # Reset CSS, import variables
│
├── components/              # GLOBAL UI (Atomic Design đơn giản)
│   ├── common/              # Các thành phần nhỏ nhất
│   │   ├── Button/          # FOLDER COMPONENT (Pattern quan trọng)
│   │   │   ├── Button.jsx   # Logic & UI chính
│   │   │   ├── Button.module.css # Style riêng biệt (Module CSS)
│   │   │   └── index.js     # File export (Barrel file)
│   │   ├── Input/
│   │   │   ├── Input.jsx
│   │   │   ├── Input.module.css
│   │   │   └── index.js
│   │   └── Modal/
│   └── layout/
│       ├── Header/
│       │   ├── Header.jsx
│       │   ├── Header.module.css
│       │   └── UserDropdown.jsx # Component con nhỏ xíu chỉ dùng trong Header
│       └── Sidebar/
│
├── configs/                 # Cấu hình môi trường & hằng số hệ thống
│   ├── app.config.js        # Config pagination limit, timeout
│   └── routes.config.js     # List danh sách routes (dùng để render động)
│
├── context/
│   └── AuthContext/         # Tách Context thành folder nếu logic phức tạp
│       ├── AuthContext.jsx  # Tạo Context
│       ├── AuthProvider.jsx # Component bao bọc (Provider)
│       └── authReducer.js   # Xử lý logic state (nếu dùng useReducer)
│
├── hooks/                   # GLOBAL HOOKS
│   ├── useAxios.js          # Hook bọc axios có loading/error state
│   └── useDebounce.js
│
├── pages/                   # MODULES (Các "Mini-Apps")
│   ├── Auth/
│   │   ├── LoginPage/       # Tách riêng từng màn hình
│   │   │   ├── LoginPage.jsx
│   │   │   └── LoginForm.jsx # Tách Form ra khỏi Page
│   │   ├── RegisterPage/
│   │   │   ├── RegisterPage.jsx
│   │   │   └── RegisterForm.jsx
│   │   └── route.js         # Định nghĩa route con cho phần Auth (nếu cần)
│   │
│   ├── Product/             # Module phức tạp nhất
│   │   ├── components/      # LOCAL COMPONENTS (Chỉ dùng cho Product)
│   │   │   ├── ProductCard/
│   │   │   │   ├── ProductCard.jsx
│   │   │   │   └── ProductCard.module.css
│   │   │   └── FilterBar/
│   │   ├── hooks/           # LOCAL HOOKS
│   │   │   └── useProductFilter.js # Logic lọc sản phẩm
│   │   ├── helpers/         # LOCAL UTILS
│   │   │   └── transformData.js # Chuyển đổi dữ liệu API trước khi render
│   │   ├── ProductList.jsx  # Trang danh sách
│   │   └── ProductDetail.jsx # Trang chi tiết
│   │
│   └── index.js             # Export tất cả pages (Lazy load imports)
│
├── services/                # API LAYER
│   ├── api/                 # Cấu hình cốt lõi
│   │   ├── axiosClient.js   # Instance chính
│   │   └── interceptors.js  # Xử lý request/response (Token, Error 401)
│   ├── auth.service.js      # Các hàm gọi API Auth
│   └── product.service.js   # Các hàm gọi API Product
│
├── utils/
│   ├── storage.js           # Wrapper cho LocalStorage (get, set, remove)
│   └── validators.js        # Hàm check regex email, phone
│
├── App.jsx
├── main.jsx
└── vite.config.js           # Cấu hình Alias (@/components...)
           # Helper functions
```


## Code Style & Conventions

### General
- **Functional Components**: Use arrow functions for components.
  ```jsx
  const ComponentName = () => { ... };
  ```
- **Exports**: Use `export default` for page components; Named exports for common components and utilities are acceptable but stay consistent.
- **Hooks**: Always use custom hooks for complex logic. Prefix with `use`.

### Naming
- **Components**: PascalCase (e.g., `ProductCard.jsx`).
- **Files**: PascalCase for components, camelCase for hooks/utils (e.g., `useAuth.js`, `formatDate.js`).
- **Variables/Functions**: camelCase.
- **Constants**: UPPER_SNAKE_CASE.

### Imports
- **React**: No need to import `React` from 'react' (JSX transform enabled).
- **Paths**: Use relative paths (e.g., `../../components/common/Button`) as no aliases are configured in `vite.config.js`.

### State Management
- Use **Context API** for global state (Auth, Theme).
- Use **Local State** (`useState`, `useReducer`) for component-specific data.
- Avoid prop drilling; utilize Context or Composition.

### API & Data Fetching
- **Service Layer**: All API calls must go through `src/services/`.
- **Axios**: Use a configured Axios instance (to be created in `src/services/api`) for interceptors and base URLs.
- **Error Handling**: Wrap async calls in `try/catch` blocks and handle errors gracefully (UI feedback).

### Routing
- Use `react-router-dom` v7.
- Define routes in a centralized configuration or standard `<Routes>` setup in `App.jsx`.
