#!/usr/bin/env python3
"""PostgreSQL database information query tool"""

import argparse
import json
import sys
import psycopg2


def get_database_info(host: str, port: int, user: str, password: str, database: str) -> dict:
    """Get detailed database information"""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )

        cursor = connection.cursor()

        # Get server version
        cursor.execute("SELECT version()")
        version = cursor.fetchone()[0]

        # Get database size
        cursor.execute("SELECT pg_database_size(%s)", (database,))
        db_size_bytes = cursor.fetchone()[0]
        db_size_mb = round(db_size_bytes / (1024 * 1024), 2)

        # Get database info
        cursor.execute("""
            SELECT
                datname,
                datdba,
                encoding,
                datcollate,
                datctype,
                datistemplate,
                datallowconn,
                datconnlimit,
                datlastsysoid,
                datfrozenxid,
                datminmxid,
                dattablespace
            FROM pg_database
            WHERE datname = %s
        """, (database,))

        db_row = cursor.fetchone()
        database_info = {
            "name": db_row[0],
            "owner": db_row[1],
            "encoding": db_row[2],
            "collate": db_row[3],
            "ctype": db_row[4],
            "is_template": db_row[5],
            "allow_connections": db_row[6],
            "connection_limit": db_row[7],
            "last_sys_oid": db_row[8],
            "frozen_xid": db_row[9],
            "min_multi_xact_id": db_row[10],
            "tablespace": db_row[11]
        }

        # Get table count
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.tables
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
        """)
        table_count = cursor.fetchone()[0]

        # Get view count
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.views
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
        """)
        view_count = cursor.fetchone()[0]

        # Get index count
        cursor.execute("""
            SELECT COUNT(*) FROM pg_indexes
            WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
        """)
        index_count = cursor.fetchone()[0]

        # Get total size of all tables
        cursor.execute("""
            SELECT COALESCE(SUM(pg_total_relation_size(c.oid)), 0)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind IN ('r', 'm')
                AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        """)
        total_table_size_bytes = cursor.fetchone()[0]
        total_table_size_mb = round(total_table_size_bytes / (1024 * 1024), 2)

        # Get PostgreSQL settings
        cursor.execute("SHOW server_version")
        server_version = cursor.fetchone()[0]

        cursor.execute("SHOW max_connections")
        max_connections = cursor.fetchone()[0]

        cursor.execute("SHOW datestyle")
        datestyle = cursor.fetchone()[0]

        cursor.close()
        connection.close()

        return {
            "success": True,
            "data": {
                "server": {
                    "version": version,
                    "server_version": server_version,
                    "max_connections": max_connections,
                    "datestyle": datestyle
                },
                "database": database_info,
                "size": {
                    "database_bytes": db_size_bytes,
                    "database_mb": db_size_mb,
                    "tables_total_bytes": total_table_size_bytes,
                    "tables_total_mb": total_table_size_mb
                },
                "objects": {
                    "table_count": table_count,
                    "view_count": view_count,
                    "index_count": index_count
                }
            },
            "message": "Database information query successful"
        }
    except psycopg2.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Database information query failed"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Database information query failed"
        }


def main():
    parser = argparse.ArgumentParser(description="View PostgreSQL database information")
    parser.add_argument("--host", default="localhost", help="Database host address")
    parser.add_argument("--port", type=int, default=5432, help="Database port")
    parser.add_argument("--user", default="postgres", help="Database username")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--database", required=True, help="Database name")

    args = parser.parse_args()

    result = get_database_info(
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
