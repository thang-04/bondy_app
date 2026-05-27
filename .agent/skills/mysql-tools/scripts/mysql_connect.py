#!/usr/bin/env python3
"""Công cụ kiểm tra kết nối cơ sở dữ liệu MySQL (Sử dụng PyMySQL)"""

import argparse
import json
import sys

try:
    import pymysql
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "pymysql chưa được cài đặt",
        "message": "Vui lòng chạy: pip install pymysql"
    }, ensure_ascii=False))
    sys.exit(1)


def test_connection(host: str, port: int, user: str, password: str, database: str) -> dict:
    """Kiểm tra kết nối cơ sở dữ liệu MySQL"""
    try:
        connection = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database,
            connect_timeout=10
        )
        
        cursor = connection.cursor()
        
        # Lấy phiên bản máy chủ
        cursor.execute("SELECT VERSION()")
        version_row = cursor.fetchone()
        server_version = version_row[0] if version_row else "Unknown"
        
        # Lấy cơ sở dữ liệu hiện tại
        cursor.execute("SELECT DATABASE()")
        db_row = cursor.fetchone()
        current_db = db_row[0] if db_row else "Unknown"
        
        cursor.close()
        connection.close()
        
        return {
            "success": True,
            "data": {
                "server_version": server_version,
                "current_database": current_db,
                "host": host,
                "port": port,
                "user": user
            },
            "message": "Kết nối cơ sở dữ liệu thành công"
        }
    except pymysql.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Kết nối cơ sở dữ liệu thất bại"
        }


def main():
    parser = argparse.ArgumentParser(description="Kiểm tra kết nối cơ sở dữ liệu MySQL")
    parser.add_argument("--host", default="localhost", help="Địa chỉ máy chủ cơ sở dữ liệu")
    parser.add_argument("--port", type=int, default=3306, help="Cổng cơ sở dữ liệu")
    parser.add_argument("--user", default="root", help="Tên người dùng cơ sở dữ liệu")
    parser.add_argument("--password", required=True, help="Mật khẩu cơ sở dữ liệu")
    parser.add_argument("--database", required=True, help="Tên cơ sở dữ liệu")
    
    args = parser.parse_args()
    
    result = test_connection(
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

    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
