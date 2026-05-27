#!/usr/bin/env python3
"""Công cụ truy vấn cấu trúc bảng cơ sở dữ liệu MySQL (Sử dụng PyMySQL)"""

import argparse
import json
import sys

try:
    import pymysql
    import pymysql.cursors
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "pymysql chưa được cài đặt",
        "message": "Vui lòng chạy: pip install pymysql"
    }, ensure_ascii=False))
    sys.exit(1)


def get_table_schema(host: str, port: int, user: str, password: str, database: str, table: str) -> dict:
    """Lấy thông tin cấu trúc của bảng được chỉ định"""
    try:
        connection = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database,
            connect_timeout=10,
            cursorclass=pymysql.cursors.DictCursor
        )
        
        cursor = connection.cursor()
        
        # Truy vấn cấu trúc bảng
        cursor.execute(f"DESCRIBE `{table}`")
        columns = cursor.fetchall()
        
        # Truy vấn thông tin chỉ mục
        cursor.execute(f"SHOW INDEX FROM `{table}`")
        indexes = cursor.fetchall()
        
        # Truy vấn thông tin bảng
        query = """
            SELECT 
                TABLE_ROWS as row_count,
                ENGINE as engine,
                TABLE_COLLATION as collation,
                CREATE_TIME as create_time,
                UPDATE_TIME as update_time,
                TABLE_COMMENT as comment
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
        """
        cursor.execute(query, (database, table))
        table_info = cursor.fetchone()
        
        # Xử lý các trường ngày giờ
        if table_info:
            for key in ['create_time', 'update_time']:
                if table_info.get(key):
                    table_info[key] = str(table_info[key])
        
        cursor.close()
        connection.close()
        
        # Sắp xếp thông tin chỉ mục
        index_map = {}
        for idx in indexes:
            idx_name = idx['Key_name']
            if idx_name not in index_map:
                index_map[idx_name] = {
                    "name": idx_name,
                    "unique": not idx['Non_unique'],
                    "columns": []
                }
            index_map[idx_name]["columns"].append(idx['Column_name'])
        
        return {
            "success": True,
            "data": {
                "table": table,
                "database": database,
                "columns": columns,
                "indexes": list(index_map.values()),
                "table_info": table_info
            },
            "message": f"Truy vấn cấu trúc bảng {table} thành công"
        }
    except pymysql.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Truy vấn cấu trúc bảng {table} thất bại"
        }


def main():
    parser = argparse.ArgumentParser(description="Xem cấu trúc bảng MySQL")
    parser.add_argument("--host", default="localhost", help="Địa chỉ máy chủ cơ sở dữ liệu")
    parser.add_argument("--port", type=int, default=3306, help="Cổng cơ sở dữ liệu")
    parser.add_argument("--user", default="root", help="Tên người dùng cơ sở dữ liệu")
    parser.add_argument("--password", required=True, help="Mật khẩu cơ sở dữ liệu")
    parser.add_argument("--database", required=True, help="Tên cơ sở dữ liệu")
    parser.add_argument("--table", required=True, help="Tên bảng")
    
    args = parser.parse_args()
    
    result = get_table_schema(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        table=args.table
    )
    
    # Đặt lại stdout để sử dụng mã hóa UTF-8
    # Sử dụng phương pháp an toàn để tránh lỗi trên Windows
    if sys.stdout.encoding.lower() != 'utf-8':
        try:
            # Dùng getattr để tránh lỗi LSP khi kiểm tra reconfigure
            reconfigure = getattr(sys.stdout, 'reconfigure', None)
            if reconfigure:
                reconfigure(encoding='utf-8')
        except Exception:
            pass # Bỏ qua nếu có lỗi

    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
