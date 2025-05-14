import datetime
import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from .models import Ticket, WeightRecord
from .database import save_weight_record, get_weight_records, get_weight_stats, init_db

# Criação do roteador
router = APIRouter()

# Diretório onde serão armazenadas as notas
OUTPUT_DIR = "tickets"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Modelo para os dados da nota
class Ticket(BaseModel):
    weight: float
    total_value: str
    timestamp: str

# Inicializa o banco de dados
init_db()

@router.post("/print_ticket")
def print_ticket(ticket: Ticket):
    """Simula a impressão de uma nota e salva no banco de dados."""
    try:
        # Salva o arquivo da nota
        filename = datetime.datetime.now().strftime("%Y%m%d_%H%M%S") + ".txt"
        file_path = os.path.join(OUTPUT_DIR, filename)

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(f"Data/Hora: {ticket.timestamp}\n")
            f.write(f"Peso: {ticket.weight:.3f} kg\n")
            f.write(f"Valor: {ticket.total_value}\n")

        # Converte o valor total de string para float
        total_value = float(ticket.total_value.replace("R$ ", "").replace(",", "."))
        
        # Converte o timestamp para datetime
        timestamp = datetime.datetime.fromisoformat(ticket.timestamp.replace('Z', '+00:00'))
        
        # Cria e salva o registro
        record = WeightRecord(
            weight=ticket.weight,
            total_value=total_value,
            timestamp=timestamp
        )
        
        saved_record = save_weight_record(record)
        return {"status": "printed", "file": file_path, "record": saved_record}
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Erro ao processar dados: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao processar ticket: {str(e)}")

@router.get("/weight_records")
def list_weight_records(start_date: str = None, end_date: str = None):
    """Lista todas as pesagens registradas."""
    try:
        start = datetime.fromisoformat(start_date) if start_date else None
        end = datetime.fromisoformat(end_date) if end_date else None
        records = get_weight_records(start, end)
        return {"records": records}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/weight_stats")
def get_stats():
    """Retorna estatísticas das pesagens."""
    try:
        stats = get_weight_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
