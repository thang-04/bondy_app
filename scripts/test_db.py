import psycopg2
try:
    conn = psycopg2.connect(
        host='103.149.86.25',
        port='5432',
        user='postgres',
        password='memaybeo',
        dbname='bondy',
        connect_timeout=5
    )
    cur = conn.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
    tables = cur.fetchall()
    print('Connection Success! Tables:', tables)
    conn.close()
except Exception as e:
    print('Connection Failed:', e)
