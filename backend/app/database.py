import sqlite3
from datetime import datetime
from typing import List
from .models import WeightRecord

DATABASE_URL = "sqlite:///./pesagens.db"

def get_db():
    conn = sqlite3.connect('pesagens.db')
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS weight_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            weight REAL NOT NULL,
            total_value REAL NOT NULL,
            timestamp DATETIME NOT NULL,
            printed BOOLEAN NOT NULL DEFAULT 1
        )
    ''')
    conn.commit()
    conn.close()

def save_weight_record(record: WeightRecord) -> WeightRecord:
    conn = get_db()
    c = conn.cursor()
    c.execute('''
        INSERT INTO weight_records (weight, total_value, timestamp, printed)
        VALUES (?, ?, ?, ?)
    ''', (record.weight, record.total_value, record.timestamp, record.printed))
    conn.commit()
    record.id = c.lastrowid
    conn.close()
    return record

def get_weight_records(start_date: datetime = None, end_date: datetime = None) -> List[WeightRecord]:
    conn = get_db()
    c = conn.cursor()
    
    query = "SELECT * FROM weight_records"
    params = []
    
    if start_date and end_date:
        query += " WHERE timestamp BETWEEN ? AND ?"
        params.extend([start_date, end_date])
    elif start_date:
        query += " WHERE timestamp >= ?"
        params.append(start_date)
    elif end_date:
        query += " WHERE timestamp <= ?"
        params.append(end_date)
    
    query += " ORDER BY timestamp DESC"
    
    c.execute(query, params)
    records = []
    for row in c.fetchall():
        records.append(WeightRecord(
            id=row['id'],
            weight=row['weight'],
            total_value=row['total_value'],
            timestamp=datetime.fromisoformat(row['timestamp']),
            printed=bool(row['printed'])
        ))
    conn.close()
    return records

def get_weight_stats() -> dict:
    conn = get_db()
    c = conn.cursor()
    
    # Total de pesagens hoje
    today = datetime.now().date()
    c.execute('''
        SELECT COUNT(*) as count, 
               SUM(total_value) as total_value,
               AVG(weight) as avg_weight
        FROM weight_records 
        WHERE date(timestamp) = date(?)
    ''', (today,))
    today_stats = c.fetchone()
    
    conn.close()
    
    return {
        'today_count': today_stats['count'] or 0,
        'today_total': today_stats['total_value'] or 0.0,
        'avg_weight': today_stats['avg_weight'] or 0.0
    } 