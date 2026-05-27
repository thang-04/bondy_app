# Tham khảo truy vấn MySQL thường dùng

## Quản lý cơ sở dữ liệu

### Xem tất cả cơ sở dữ liệu
```sql
SHOW DATABASES;
```

### Xem kích thước cơ sở dữ liệu
```sql
SELECT 
    TABLE_SCHEMA as database_name,
    ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as size_mb
FROM information_schema.TABLES 
GROUP BY TABLE_SCHEMA
ORDER BY size_mb DESC;
```

### Xem bộ ký tự cơ sở dữ liệu
```sql
SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'your_database';
```

## Thao tác bảng

### Xem cấu trúc bảng
```sql
DESCRIBE table_name;
-- Hoặc chi tiết hơn
SHOW CREATE TABLE table_name;
```

### Xem chỉ mục bảng
```sql
SHOW INDEX FROM table_name;
```

### Xem trạng thái bảng
```sql
SHOW TABLE STATUS LIKE 'table_name';
```

### Xem tất cả khóa ngoại
```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_SCHEMA = 'your_database'
    AND REFERENCED_TABLE_NAME IS NOT NULL;
```

## Phân tích dữ liệu

### Thống kê số lượng bản ghi
```sql
SELECT COUNT(*) FROM table_name;
```

### Thống kê nhóm
```sql
SELECT column_name, COUNT(*) as count
FROM table_name
GROUP BY column_name
ORDER BY count DESC;
```

### Xem tình trạng giá trị rỗng
```sql
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN column_name IS NULL THEN 1 ELSE 0 END) as null_count
FROM table_name;
```

### Lấy mẫu dữ liệu
```sql
-- Lấy ngẫu nhiên 10 dòng
SELECT * FROM table_name ORDER BY RAND() LIMIT 10;

-- Truy vấn phân trang
SELECT * FROM table_name LIMIT 10 OFFSET 0;
```

## Phân tích hiệu suất

### Xem truy vấn chậm
```sql
SHOW VARIABLES LIKE 'slow_query%';
```

### Xem kết nối hiện tại
```sql
SHOW PROCESSLIST;
```

### Xem khóa bảng
```sql
SHOW OPEN TABLES WHERE In_use > 0;
```

### Phân tích kế hoạch truy vấn
```sql
EXPLAIN SELECT * FROM table_name WHERE column = 'value';
```

## Xuất dữ liệu

### Xuất sang định dạng CSV
```sql
SELECT * FROM table_name
INTO OUTFILE '/tmp/export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

### Định dạng kết quả truy vấn
```sql
-- Định dạng ngày tháng
SELECT DATE_FORMAT(create_time, '%Y-%m-%d %H:%i:%s') FROM table_name;

-- Định dạng số
SELECT FORMAT(price, 2) FROM table_name;
```

## Sửa đổi dữ liệu

### Chế độ cập nhật an toàn
```sql
-- Tắt chế độ an toàn (cho phép UPDATE/DELETE không có WHERE)
SET SQL_SAFE_UPDATES = 0;

-- Bật chế độ an toàn
SET SQL_SAFE_UPDATES = 1;
```

### Cập nhật hàng loạt
```sql
UPDATE table_name 
SET column = 'new_value' 
WHERE condition;
```

### Xóa hàng loạt
```sql
DELETE FROM table_name WHERE condition;
```

## Hàm thường dùng

### Hàm chuỗi
```sql
CONCAT(str1, str2)           -- Nối chuỗi
SUBSTRING(str, start, len)   -- Cắt chuỗi
TRIM(str)                    -- Loại bỏ khoảng trắng
UPPER(str) / LOWER(str)      -- Chuyển đổi chữ hoa/thường
LENGTH(str)                  -- Độ dài chuỗi
```

### Hàm ngày tháng
```sql
NOW()                        -- Thời gian hiện tại
CURDATE()                    -- Ngày hiện tại
DATE_ADD(date, INTERVAL n DAY)  -- Cộng/trừ ngày
DATEDIFF(date1, date2)       -- Chênh lệch ngày
```

### Hàm tổng hợp
```sql
COUNT(*), SUM(col), AVG(col), MAX(col), MIN(col)
```
