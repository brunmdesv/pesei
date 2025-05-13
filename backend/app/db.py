import sqlite3

DB_PATH = "restaurante.db"

def get_connection():
    """Retorna uma conexão com o banco de dados SQLite."""
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Inicializa o banco de dados com a tabela de configuração."""
    conn = get_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    """)
    # Insere valor padrão para o preço por kg, se não existir
    conn.execute("INSERT OR IGNORE INTO config (key, value) VALUES (?, ?)", ("price_per_kg", "0.00"))
    conn.commit()
    conn.close()
