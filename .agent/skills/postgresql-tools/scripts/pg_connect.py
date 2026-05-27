#!/usr/bin/env python3
"""PostgreSQL database connection test tool"""

import argparse
import json
import sys
import psycopg2
from psycopg2 import sql


def test_connection(host: str, port: int, user: str, password: str, database: str) -> dict:
    """Test PostgreSQL database connection"""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )

        cursor = connection.cursor()

        # Get PostgreSQL version
        cursor.execute("SELECT version()")
        version = cursor.fetchone()[0]

        # Get server info
        cursor.execute("SHOW server_version")
        server_version = cursor.fetchone()[0]

        cursor.execute("SHOW datestyle")
        datestyle = cursor.fetchone()[0]

        # Get database size
        cursor.execute("SELECT pg_database_size(%s)", (database,))
        db_size_bytes = cursor.fetchone()[0]
        db_size_mb = round(db_size_bytes / (1024 * 1024), 2)

        # Get table count
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.tables
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
        """)
        table_count = cursor.fetchone()[0]

        cursor.close()
        connection.close()

        return {
            "success": True,
            "data": {
                "host": host,
                "port": port,
                "database": database,
                "user": user,
                "server_version": server_version,
                "datestyle": datestyle,
                "database_size_bytes": db_size_bytes,
                "database_size_mb": db_size_mb,
                "table_count": table_count
            },
            "message": "Database connection successful"
        }
    except psycopg2.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Database connection failed"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Database connection failed"
        }


def main():
    parser = argparse.ArgumentParser(description="Test PostgreSQL database connection")
    parser.add_argument("--host", default="localhost", help="Database host address")
    parser.add_argument("--port", type=int, default=5432, help="Database port")
    parser.add_argument("--user", default="postgres", help="Database username")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--database", required=True, help="Database name")

    args = parser.parse_args()

    result = test_connection(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
