#!/usr/bin/env python3
"""PostgreSQL SQL query execution tool"""

import argparse
import json
import sys
import psycopg2
from datetime import datetime, date


class CustomJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder for PostgreSQL types"""
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        if isinstance(obj, bytes):
            return obj.decode('utf-8', errors='replace')
        return super().default(obj)


def execute_query(host: str, port: int, user: str, password: str, database: str, query: str, readonly: bool = False) -> dict:
    """Execute SQL query"""
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )

        cursor = connection.cursor()

        # Determine if it's a SELECT query
        query_upper = query.strip().upper()
        is_select = (
            query_upper.startswith("SELECT") or
            query_upper.startswith("WITH") or
            query_upper.startswith("EXPLAIN") or
            query_upper.startswith("SHOW") or
            query_upper.startswith("DESCRIBE") or
            query_upper.startswith("VACUUM") or
            query_upper.startswith("ANALYZE")
        )

        if readonly and not is_select:
            return {
                "success": False,
                "error": "Read-only mode: cannot execute write operations",
                "message": "Query execution failed"
            }

        cursor.execute(query)

        if is_select:
            columns = [description[0] for description in cursor.description] if cursor.description else []
            rows_raw = cursor.fetchall()
            rows = []
            for row in rows_raw:
                row_dict = {}
                for i, col in enumerate(columns):
                    value = row[i]
                    if isinstance(value, (datetime, date)):
                        row_dict[col] = value.isoformat()
                    elif isinstance(value, bytes):
                        row_dict[col] = value.decode('utf-8', errors='replace')
                    else:
                        row_dict[col] = value
                rows.append(row_dict)

            result = {
                "success": True,
                "data": {
                    "rows": rows,
                    "row_count": len(rows),
                    "columns": columns
                },
                "message": f"Query successful, returned {len(rows)} rows"
            }
        else:
            connection.commit()
            affected_rows = cursor.rowcount
            result = {
                "success": True,
                "data": {
                    "affected_rows": affected_rows
                },
                "message": f"Execution successful, affected {affected_rows} rows"
            }

        cursor.close()
        connection.close()

        return result
    except psycopg2.Error as e:
        return {
            "success": False,
            "error": str(e),
            "message": "SQL execution failed"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "SQL execution failed"
        }


def main():
    parser = argparse.ArgumentParser(description="Execute PostgreSQL SQL query")
    parser.add_argument("--host", default="localhost", help="Database host address")
    parser.add_argument("--port", type=int, default=5432, help="Database port")
    parser.add_argument("--user", default="postgres", help="Database username")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--database", required=True, help="Database name")
    parser.add_argument("--query", required=True, help="SQL statement to execute")
    parser.add_argument("--readonly", action="store_true", help="Read-only mode")

    args = parser.parse_args()

    result = execute_query(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
        query=args.query,
        readonly=args.readonly
    )

    print(json.dumps(result, ensure_ascii=False, indent=2, cls=CustomJSONEncoder))
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
