#!/usr/bin/env python3
"""PostgreSQL database table listing tool"""

import argparse
import json
import sys
import psycopg2
from psycopg2 import sql


def list_tables(host: str, port: int, user: str, password: str, database: str) -> dict:
    """List all tables in the database"""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )

        cursor = connection.cursor()

        # Query all tables and views
        cursor.execute("""
            SELECT
                t.table_name,
                t.table_type,
                t.table_schema,
                (SELECT COUNT(*) FROM information_schema.columns c WHERE c.table_name = t.table_name AND c.table_schema = t.table_schema) as column_count
            FROM information_schema.tables t
            WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY t.table_type, t.table_name
        """)

        tables = []
        for row in cursor.fetchall():
            table_name = row[0]
            table_type = row[1]
            table_schema = row[2]
            column_count = row[3]

            # Get row count for each table
            row_count = None
            try:
                cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                    sql.Identifier(table_schema),
                    sql.Identifier(table_name)
                ))
                row_count = cursor.fetchone()[0]
            except Exception:
                row_count = None

            tables.append({
                "table_name": table_name,
                "table_type": table_type,
                "table_schema": table_schema,
                "column_count": column_count,
                "row_count": row_count
            })

        cursor.close()
        connection.close()

        return {
            "success": True,
            "data": {
                "database": database,
                "table_count": len(tables),
                "tables": tables
            },
            "message": f"Found {len(tables)} tables"
        }
    except psycopg2.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Failed to query table list"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Failed to query table list"
        }


def main():
    parser = argparse.ArgumentParser(description="List all tables in PostgreSQL database")
    parser.add_argument("--host", default="localhost", help="Database host address")
    parser.add_argument("--port", type=int, default=5432, help="Database port")
    parser.add_argument("--user", default="postgres", help="Database username")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--database", required=True, help="Database name")

    args = parser.parse_args()

    result = list_tables(
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
