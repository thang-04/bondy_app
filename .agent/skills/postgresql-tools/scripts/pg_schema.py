#!/usr/bin/env python3
"""PostgreSQL table schema查询工具"""

import argparse
import json
import sys
import psycopg2
from psycopg2 import sql


def get_table_schema(host: str, port: int, user: str, password: str, database: str, table: str, schema: str = "public") -> dict:
    """Get table structure information"""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )

        cursor = connection.cursor()

        # Get column information
        cursor.execute("""
            SELECT
                c.column_name,
                c.data_type,
                c.column_default,
                c.is_nullable,
                c.character_maximum_length,
                c.numeric_precision,
                c.numeric_scale,
                c.datetime_precision,
                c.is_identity,
                c.is_updatable
            FROM information_schema.columns c
            WHERE c.table_name = %s AND c.table_schema = %s
            ORDER BY c.ordinal_position
        """, (table, schema))

        columns = []
        for row in cursor.fetchall():
            columns.append({
                "column_name": row[0],
                "data_type": row[1],
                "default_value": row[2],
                "nullable": row[3] == "YES",
                "max_length": row[4],
                "precision": row[5],
                "scale": row[6],
                "datetime_precision": row[7],
                "is_identity": row[8] == "YES",
                "is_updatable": row[9] == "YES"
            })

        # Get primary key information
        cursor.execute("""
            SELECT
                kcu.column_name,
                kcu.constraint_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.constraint_type = 'PRIMARY KEY'
                AND tc.table_name = %s
                AND tc.table_schema = %s
        """, (table, schema))

        primary_keys = {row[0]: row[1] for row in cursor.fetchall()}

        # Get index information
        cursor.execute("""
            SELECT
                i.relname as index_name,
                ix.indexdef,
                am.amname as index_type
            FROM pg_class c
            JOIN pg_index ix ON c.oid = ix.indrelid
            JOIN pg_class i ON i.oid = ix.indexrelid
            JOIN pg_am am ON i.relam = am.oid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = %s AND n.nspname = %s
                AND ix.indisprimary = FALSE
            ORDER BY i.relname
        """, (table, schema))

        indexes = []
        for row in cursor.fetchall():
            index_name = row[0]
            # Get columns for this index
            cursor.execute("""
                SELECT a.attname
                FROM pg_index ix
                JOIN pg_attribute a ON a.attrelid = ix.indrelid AND a.attnum = ANY(ix.indkey)
                WHERE ix.indrelid = %s::regclass AND i.relname = %s
            """, (f"{schema}.{table}", index_name))
            idx_columns = [col[0] for col in cursor.fetchall()]

            indexes.append({
                "name": index_name,
                "definition": row[1],
                "type": row[2],
                "columns": idx_columns
            })

        # Get foreign key information
        cursor.execute("""
            SELECT
                tc.constraint_name,
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name,
                ccu.table_schema AS foreign_table_schema
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND tc.table_name = %s
                AND tc.table_schema = %s
        """, (table, schema))

        foreign_keys = []
        for row in cursor.fetchall():
            foreign_keys.append({
                "constraint_name": row[0],
                "column": row[1],
                "foreign_table": row[2],
                "foreign_column": row[3],
                "foreign_schema": row[4]
            })

        # Get row count
        row_count = None
        try:
            cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                sql.Identifier(schema),
                sql.Identifier(table)
            ))
            row_count = cursor.fetchone()[0]
        except Exception:
            row_count = None

        cursor.close()
        connection.close()

        # Add primary key info to columns
        for col in columns:
            if col["column_name"] in primary_keys:
                col["is_primary_key"] = True
                col["primary_key_constraint"] = primary_keys[col["column_name"]]
            else:
                col["is_primary_key"] = False
                col["primary_key_constraint"] = None

        return {
            "success": True,
            "data": {
                "table": table,
                "schema": schema,
                "columns": columns,
                "indexes": indexes,
                "foreign_keys": foreign_keys,
                "row_count": row_count
            },
            "message": f"Table {table} schema query successful"
        }
    except psycopg2.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Failed to query table {table} schema"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Failed to query table {table} schema"
        }


def main():
    parser = argparse.ArgumentParser(description="View PostgreSQL table schema")
    parser.add_argument("--host", default="localhost", help="Database host address")
    parser.add_argument("--port", type=int, default=5432, help="Database port")
    parser.add_argument("--user", default="postgres", help="Database username")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--database", required=True, help="Database name")
    parser.add_argument("--table", required=True, help="Table name")
    parser.add_argument("--schema", default="public", help="Schema name (default: public)")

    args = parser.parse_args()

    result = get_table_schema(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        table=args.table,
        schema=args.schema
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
