import datetime
import os
from fastapi import APIRouter
from pydantic import BaseModel

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

@router.post("/print_ticket")
def print_ticket(ticket: Ticket):
    """Simula a impressão de uma nota."""
    filename = datetime.datetime.now().strftime("%Y%m%d_%H%M%S") + ".txt"
    file_path = os.path.join(OUTPUT_DIR, filename)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(f"Data/Hora: {ticket.timestamp}\n")
        f.write(f"Peso: {ticket.weight:.3f} kg\n")
        f.write(f"Valor: {ticket.total_value}\n")

    print(f"[Simulação] Nota impressa em {file_path}")
    return {"status": "printed", "file": file_path}
