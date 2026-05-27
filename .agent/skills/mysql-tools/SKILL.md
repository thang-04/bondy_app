---
name: mysql-tools
description: "Bộ công cụ cơ sở dữ liệu MySQL, được sử dụng để kết nối với các phiên bản cơ sở dữ liệu, liệt kê tất cả các bảng, xem cấu trúc bảng, thực thi các truy vấn SQL và các hoạt động khác. QUAN TRỌNG: Khi người dùng yêu cầu sử dụng kỹ năng này, việc ĐẦU TIÊN cần làm là hỏi người dùng cung cấp Host, User, Password và Database trước khi thực hiện bất kỳ thao tác nào khác (trừ khi người dùng đã cung cấp sẵn). Sử dụng kỹ năng này khi bạn cần thao tác cơ sở dữ liệu MySQL, truy vấn dữ liệu và phân tích cấu trúc bảng. Hỗ trợ chỉ định thông tin kết nối như máy chủ, cổng, người dùng, mật khẩu, cơ sở dữ liệu thông qua các tham số dòng lệnh và có thể được sử dụng thay thế cho dịch vụ mysql mcp. Hỗ trợ các nền tảng Windows, macOS và Linux."
---

# Kỹ năng Công cụ MySQL

Bộ công cụ để vận hành cơ sở dữ liệu MySQL, cung cấp các chức năng kiểm tra kết nối, quản lý bảng và thực thi SQL.

## Bắt đầu nhanh

### Yêu cầu trước

```bash
pip install pymysql
```

### Khả năng tương thích nền tảng

- ✅ Windows
- ✅ macOS
- ✅ Linux

### Tham số kết nối

Tất cả các tập lệnh đều hỗ trợ các tham số sau:

| Tham số | Mô tả | Giá trị mặc định |
|---|---|---|
| `--host` | Địa chỉ máy chủ cơ sở dữ liệu | localhost |
| `--port` | Cổng cơ sở dữ liệu | 3306 |
| `--user` | Tên người dùng cơ sở dữ liệu | root |
| `--password` | Mật khẩu cơ sở dữ liệu | Bắt buộc |
| `--database` | Tên cơ sở dữ liệu | Bắt buộc |

## Các tập lệnh có sẵn

### 1. Kiểm tra kết nối cơ sở dữ liệu

Xác minh xem các tham số kết nối cơ sở dữ liệu có chính xác không:

```bash
python scripts/mysql_connect.py --host 127.0.0.1 --port 3306 --user root --password YOUR_PASSWORD --database YOUR_DB
```

### 2. Liệt kê tất cả các bảng

Lấy tất cả tên bảng trong cơ sở dữ liệu:

```bash
python scripts/mysql_tables.py --host 127.0.0.1 --user root --password YOUR_PASSWORD --database YOUR_DB
```

Định dạng đầu ra: Danh sách tên bảng, bao gồm loại bảng (BASE TABLE / VIEW)

### 3. Xem cấu trúc bảng

Hiển thị thông tin trường của bảng được chỉ định:

```bash
python scripts/mysql_schema.py --host 127.0.0.1 --user root --password YOUR_PASSWORD --database YOUR_DB --table TABLE_NAME
```

Định dạng đầu ra: tên trường, loại, có thể null, loại khóa, giá trị mặc định, thông tin bổ sung

### 4. Thực thi truy vấn SQL

Chạy bất kỳ câu lệnh SQL nào:

```bash
python scripts/mysql_query.py --host 127.0.0.1 --user root --password YOUR_PASSWORD --database YOUR_DB --query "SELECT * FROM users LIMIT 10"
```

Hỗ trợ tất cả các câu lệnh SQL như SELECT, INSERT, UPDATE, DELETE.

### 5. Xem thông tin cơ sở dữ liệu

Lấy phiên bản cơ sở dữ liệu, kích thước và các thông tin khác:

```bash
python scripts/mysql_info.py --host 127.0.0.1 --user root --password YOUR_PASSWORD --database YOUR_DB
```

## Định dạng đầu ra

Tất cả các tập lệnh đều xuất dữ liệu định dạng JSON để dễ dàng phân tích cú pháp:

```json
{
  "success": true,
  "data": [...],
  "message": "Thao tác thành công"
}
```

Trả về khi có lỗi:

```json
{
  "success": false,
  "error": "Thông tin lỗi",
  "message": "Thao tác thất bại"
}
```

## Các trường hợp sử dụng phổ biến

### Khám phá cơ sở dữ liệu mới

1. Kiểm tra kết nối: `mysql_connect.py`
2. Liệt kê tất cả các bảng: `mysql_tables.py`
3. Xem cấu trúc bảng chính: `mysql_schema.py --table TABLE_NAME`
4. Truy vấn dữ liệu mẫu: `mysql_query.py --query "SELECT * FROM TABLE_NAME LIMIT 5"`

### Phân tích dữ liệu

1. Lấy số lượng bản ghi bảng: `mysql_query.py --query "SELECT COUNT(*) FROM TABLE_NAME"`
2. Phân tích phân phối dữ liệu: `mysql_query.py --query "SELECT column, COUNT(*) FROM TABLE_NAME GROUP BY column"`

### Tham khảo thêm ví dụ SQL

Xem `references/common_queries.md` để biết các mẫu truy vấn SQL phổ biến.
