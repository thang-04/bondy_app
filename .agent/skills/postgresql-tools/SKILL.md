---
name: postgresql-tools
description: "PostgreSQL database utilities for connecting to databases, listing tables, viewing table schema, executing SQL queries, and more. Use when working with PostgreSQL databases, querying data, or analyzing table structures. Supports connection parameters like host, port, user, password, database. Compatible with Windows, macOS, and Linux."
---

# PostgreSQL Tools Skill

Collection of utilities for operating PostgreSQL databases, providing connection testing, table management, and SQL execution.

## Quick Start

### Prerequisites

```bash
pip install psycopg2
```

### Platform Compatibility

- ✅ Windows
- ✅ macOS
- ✅ Linux

### Connection Parameters

All scripts support the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--host` | Database host address | localhost |
| `--port` | Database port | 5432 |
| `--user` | Database username | postgres |
| `--password` | Database password | required |
| `--database` | Database name | required |

## Available Scripts

### 1. Test Database Connection

Verify database connection parameters:

```bash
python scripts/pg_connect.py --host 127.0.0.1 --port 5432 --user postgres --password YOUR_PASSWORD --database YOUR_DB
```

### 2. List All Tables

Get all tables in the database:

```bash
python scripts/pg_tables.py --host 127.0.0.1 --user postgres --password YOUR_PASSWORD --database YOUR_DB
```

Output: Table list with type (BASE TABLE / VIEW), column count, and row count.

### 3. View Table Schema

Display field information for a specific table:

```bash
python scripts/pg_schema.py --host 127.0.0.1 --user postgres --password YOUR_PASSWORD --database YOUR_DB --table TABLE_NAME
```

Output: Column name, data type, nullable, key type, default value, and extra info.

### 4. Execute SQL Query

Run any SQL statement:

```bash
python scripts/pg_query.py --host 127.0.0.1 --user postgres --password YOUR_PASSWORD --database YOUR_DB --query "SELECT * FROM users LIMIT 10"
```

Supports SELECT, INSERT, UPDATE, DELETE, and all other SQL statements.

### 5. View Database Info

Get database version, size, and other information:

```bash
python scripts/pg_info.py --host 127.0.0.1 --user postgres --password YOUR_PASSWORD --database YOUR_DB
```

## Output Format

All scripts output JSON format data for easy parsing:

```json
{
  "success": true,
  "data": [...],
  "message": "Operation successful"
}
```

On error:

```json
{
  "success": false,
  "error": "Error message",
  "message": "Operation failed"
}
```

## Common Use Cases

### Exploring a New Database

1. Test connection: `pg_connect.py`
2. List all tables: `pg_tables.py`
3. View table schema: `pg_schema.py --table TABLE_NAME`
4. Query sample data: `pg_query.py --query "SELECT * FROM TABLE_NAME LIMIT 5"`

### Data Analysis

1. Get row count: `pg_query.py --query "SELECT COUNT(*) FROM TABLE_NAME"`
2. Analyze data distribution: `pg_query.py --query "SELECT column, COUNT(*) FROM TABLE_NAME GROUP BY column"`

### Read-Only Mode

All scripts support `--readonly` flag for safe read-only access (no modifications):

```bash
python scripts/pg_query.py --host 127.0.0.1 --user postgres --password YOUR_PASSWORD --database YOUR_DB --query "SELECT * FROM users" --readonly
```

### Reference

See `references/common_queries.md` for common SQL query templates.
