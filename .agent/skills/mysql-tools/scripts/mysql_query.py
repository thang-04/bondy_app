#!/usr/bin/env python3
"""Công cụ thực thi truy vấn SQL MySQL (Sử dụng PyMySQL)"""

import argparse
import json
import sys
from decimal import Decimal
from datetime import datetime, date, timedelta

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
    """Bộ mã hóa JSON tùy chỉnh, xử lý các loại dữ liệu đặc biệt"""
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        if isinstance(o, (datetime, date)):
            return o.isoformat()
        if isinstance(o, timedelta):
            return str(o)
        if isinstance(o, bytes):
            return o.decode('utf-8', errors='replace')
        return super().default(o)


def execute_query(host: str, port: int, user: str, password: str, database: str, query: str) -> dict:
    """Thực thi truy vấn SQL"""
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
        
        # Xác định xem có phải là truy vấn SELECT không
        query_upper = query.strip().upper()
        is_select = (
            query_upper.startswith("SELECT") or 
            query_upper.startswith("SHOW") or 
            query_upper.startswith("DESCRIBE") or 
            query_upper.startswith("EXPLAIN")
        )
        
        cursor.execute(query)
        
        if is_select:
            rows = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description] if cursor.description else []
            result = {
                "success": True,
                "data": {
                    "rows": rows,
                    "row_count": len(rows),
                    "columns": columns
                },
                "message": f"Truy vấn thành công, trả về {len(rows)} hàng"
            }
        else:
            connection.commit()
            affected_rows = cursor.rowcount
            result = {
                "success": True,
                "data": {
                    "affected_rows": affected_rows,
                    "last_insert_id": cursor.lastrowid
                },
                "message": f"Thực thi thành công, ảnh hưởng {affected_rows} hàng"
            }
        
        cursor.close()
        connection.close()
        
        return result
    except pymysql.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Thực thi SQL thất bại"
        }


def main():
    parser = argparse.ArgumentParser(description="Thực thi truy vấn SQL MySQL")
    parser.add_argument("--host", default="localhost", help="Địa chỉ máy chủ cơ sở dữ liệu")
    parser.add_argument("--port", type=int, default=3306, help="Cổng cơ sở dữ liệu")
    parser.add_argument("--user", default="root", help="Tên người dùng cơ sở dữ liệu")
    parser.add_argument("--password", required=True, help="Mật khẩu cơ sở dữ liệu")
    parser.add_argument("--database", required=True, help="Tên cơ sở dữ liệu")
    parser.add_argument("--query", required=True, help="Câu lệnh SQL cần thực thi")
    
    args = parser.parse_args()
    
    result = execute_query(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        query=args.query
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
