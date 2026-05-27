#!/usr/bin/env python3
"""Công cụ truy vấn danh sách bảng cơ sở dữ liệu MySQL (Sử dụng PyMySQL)"""

import argparse
import json
import sys
from decimal import Decimal

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


class CustomJSONEncoder(json.JSONEncoder):
    """Bộ mã hóa JSON tùy chỉnh, xử lý loại Decimal"""
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        return super().default(o)


def list_tables(host: str, port: int, user: str, password: str, database: str) -> dict:
    """Liệt kê tất cả các bảng trong cơ sở dữ liệu"""
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
        
        # Truy vấn tất cả các bảng và chế độ xem
        query = """
            SELECT 
                TABLE_NAME as table_name,
                TABLE_TYPE as table_type,
                ENGINE as engine,
                TABLE_ROWS as row_count,
                ROUND(DATA_LENGTH / 1024 / 1024, 2) as data_size_mb,
                TABLE_COMMENT as comment
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = %s
            ORDER BY TABLE_NAME
        """
        cursor.execute(query, (database,))
        tables = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return {
            "success": True,
            "data": {
                "database": database,
                "table_count": len(tables),
                "tables": tables
            },
            "message": f"Tìm thấy {len(tables)} bảng"
        }
    except pymysql.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Truy vấn danh sách bảng thất bại"
        }


def main():
    parser = argparse.ArgumentParser(description="Liệt kê tất cả các bảng trong cơ sở dữ liệu MySQL")
    parser.add_argument("--host", default="localhost", help="Địa chỉ máy chủ cơ sở dữ liệu")
    parser.add_argument("--port", type=int, default=3306, help="Cổng cơ sở dữ liệu")
    parser.add_argument("--user", default="root", help="Tên người dùng cơ sở dữ liệu")
    parser.add_argument("--password", required=True, help="Mật khẩu cơ sở dữ liệu")
    parser.add_argument("--database", required=True, help="Tên cơ sở dữ liệu")
    
    args = parser.parse_args()
    
    result = list_tables(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
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

    print(json.dumps(result, ensure_ascii=False, indent=2, cls=CustomJSONEncoder))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
