# PostgreSQL Common Queries Reference

## Table Operations

### View All Tables
```sql
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### View Table Structure
```sql
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'table_name' AND table_schema = 'public'
ORDER BY ordinal_position;
```

### Get Table CREATE Statement
```sql
SELECT pg_catalog.pg_get_trigger_result(r.oid) AS sql
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname = 'table_name' AND n.nspname = 'public';
```

### Get Complete Table Info
```sql
SELECT
    c.relname AS table_name,
    c.relkind,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'm')
    AND n.nspname = 'public'
ORDER BY pg_total_relation_size(c.oid) DESC;
```

## Data Query

### Pagination
```sql
SELECT * FROM table_name LIMIT 10 OFFSET 20;
```

### Count Rows
```sql
SELECT COUNT(*) FROM table_name;
```

### Fuzzy Search
```sql
SELECT * FROM table_name WHERE column LIKE '%keyword%';
```

### Multiple Conditions
```sql
SELECT * FROM table_name
WHERE condition1 = 'value1'
    AND condition2 > 100
ORDER BY created_at DESC
LIMIT 50;
```

## Index Operations

### View All Indexes
```sql
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### View Index Details
```sql
SELECT
    i.relname AS index_name,
    a.attname AS column_name,
    ix.indisunique AS is_unique,
    ix.indisprimary AS is_primary
FROM pg_index ix
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_attribute a ON a.attrelid = ix.indrelid AND a.attnum = ANY(ix.indkey)
WHERE ix.indrelid = 'table_name'::regclass
ORDER BY i.relname, a.attnum;
```

### Find Missing Indexes
```sql
SELECT
    schemaname,
    tablename,
    seq_scan,
    idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan * 10
    AND idx_scan > 0
ORDER BY seq_scan DESC;
```

## Database Information

### PostgreSQL Version
```sql
SELECT version();
```

### Database Size
```sql
SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
WHERE datname = current_database();
```

### Table Sizes
```sql
SELECT
    relname,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS indexes_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

### Connection Info
```sql
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    backend_start,
    state
FROM pg_stat_activity
WHERE datname = current_database();
```

## Common Operations

### Kill Idle Connections
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
    AND state_change < NOW() - INTERVAL '10 minutes';
```

### Vacuum to Reclaim Space
```sql
VACUUM (VERBOSE, ANALYZE) table_name;
```

### Reset Table Statistics
```sql
TRUNCATE TABLE table_name RESTART IDENTITY;
```

### View Query Performance
```sql
EXPLAIN ANALYZE SELECT * FROM table_name WHERE condition;
```
