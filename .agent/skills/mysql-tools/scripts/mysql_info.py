#!/usr/bin/env python3
"""Công cụ truy vấn thông tin cơ sở dữ liệu MySQL (Sử dụng PyMySQL)"""

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


def get_database_info(host: str, port: int, user: str, password: str, database: str) -> dict:
    """Lấy thông tin chi tiết về cơ sở dữ liệu"""
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
        
        # Lấy thông tin phiên bản máy chủ
        cursor.execute("SELECT VERSION()")
        version_row = cursor.fetchone()
        server_version = version_row['VERSION()'] if version_row else "Unknown"
        
        # Lấy thông tin kích thước cơ sở dữ liệu
        size_query = """
            SELECT 
                TABLE_SCHEMA as db_name,
                COUNT(*) as table_count,
                ROUND(SUM(DATA_LENGTH) / 1024 / 1024, 2) as data_size_mb,
                ROUND(SUM(INDEX_LENGTH) / 1024 / 1024, 2) as index_size_mb,
                ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as total_size_mb
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = %s
            GROUP BY TABLE_SCHEMA
        """
        cursor.execute(size_query, (database,))
        size_info = cursor.fetchone()
        
        # Lấy bộ ký tự và quy tắc sắp xếp của cơ sở dữ liệu
        charset_query = """
            SELECT 
                DEFAULT_CHARACTER_SET_NAME as charset,
                DEFAULT_COLLATION_NAME as collation
            FROM information_schema.SCHEMATA 
            WHERE SCHEMA_NAME = %s
        """
        cursor.execute(charset_query, (database,))
        charset_info = cursor.fetchone()
        
        # Lấy thông tin trạng thái máy chủ
        cursor.execute("SHOW STATUS LIKE 'Uptime'")
        uptime_row = cursor.fetchone()
        uptime_seconds = int(uptime_row['Value']) if uptime_row else 0
        
        # Lấy thông tin kết nối
        cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
        threads_row = cursor.fetchone()
        threads_connected = int(threads_row['Value']) if threads_row else 0
        
        # Lấy số kết nối tối đa
        cursor.execute("SHOW VARIABLES LIKE 'max_connections'")
        max_conn_row = cursor.fetchone()
        max_connections = int(max_conn_row['Value']) if max_conn_row else 0
        
        cursor.close()
        connection.close()
        
        # Định dạng thời gian chạy
        days = uptime_seconds // 86400
        hours = (uptime_seconds % 86400) // 3600
        minutes = (uptime_seconds % 3600) // 60
        uptime_formatted = f"{days} ngày {hours} giờ {minutes} phút"
        
        return {
            "success": True,
            "data": {
                "server": {
                    "version": server_version,
                    "host": host,
                    "port": port,
                    "uptime": uptime_formatted,
                    "uptime_seconds": uptime_seconds
                },
                "database": {
                    "name": database,
                    "charset": charset_info.get('charset') if charset_info else None,
                    "collation": charset_info.get('collation') if charset_info else None,
                    "table_count": size_info.get('table_count') if size_info else 0,
                    "data_size_mb": float(size_info.get('data_size_mb') or 0) if size_info else 0,
                    "index_size_mb": float(size_info.get('index_size_mb') or 0) if size_info else 0,
                    "total_size_mb": float(size_info.get('total_size_mb') or 0) if size_info else 0
                },
                "connections": {
                    "current": threads_connected,
                    "max": max_connections
                }
            },
            "message": "Truy vấn thông tin cơ sở dữ liệu thành công"
        }
    except pymysql.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Truy vấn thông tin cơ sở dữ liệu thất bại"
        }


def main():
    parser = argparse.ArgumentParser(description="Xem thông tin cơ sở dữ liệu MySQL")
    parser.add_argument("--host", default="localhost", help="Địa chỉ máy chủ cơ sở dữ liệu")
    parser.add_argument("--port", type=int, default=3306, help="Cổng cơ sở dữ liệu")
    parser.add_argument("--user", default="root", help="Tên người dùng cơ sở dữ liệu")
    parser.add_argument("--password", required=True, help="Mật khẩu cơ sở dữ liệu")
    parser.add_argument("--database", required=True, help="Tên cơ sở dữ liệu")
    
    args = parser.parse_args()
    
    result = get_database_info(
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
