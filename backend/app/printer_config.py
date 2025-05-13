import os
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict

router = APIRouter()

# Modelos para validação de dados
class PrinterMargins(BaseModel):
    top: float
    bottom: float
    left: float
    right: float

class PrinterSettings(BaseModel):
    printer_name: str
    margins: PrinterMargins

# Arquivo de configuração
CONFIG_FILE = "printer_config.json"

def load_config() -> Dict:
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return {
        "printer_name": "",
        "margins": {
            "top": 0.0,
            "bottom": 0.0,
            "left": 0.0,
            "right": 0.0
        }
    }

def save_config(config: Dict):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)

@router.get("/admin/printers")
async def get_printers():
    """Retorna lista de impressoras disponíveis."""
    # Simulação de impressoras disponíveis
    return {
        "printers": [
            "Impressora Térmica 1",
            "Impressora Térmica 2",
            "Impressora Padrão"
        ]
    }

@router.get("/admin/printer_settings")
async def get_printer_settings():
    """Retorna as configurações atuais da impressora."""
    return load_config()

@router.post("/admin/printer_settings")
async def update_printer_settings(settings: PrinterSettings):
    """Atualiza as configurações da impressora."""
    config = {
        "printer_name": settings.printer_name,
        "margins": settings.margins.dict()
    }
    save_config(config)
    return {"status": "success", "settings": config}

@router.post("/admin/test_print")
async def test_print():
    """Simula o envio de uma nota de teste."""
    try:
        # Simulação de impressão de teste
        test_content = """
        ================================
        TESTE DE IMPRESSÃO
        ================================
        Data/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        ================================
        """
        print(test_content)
        return {"status": "success", "message": "Teste enviado com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/printer_status")
async def get_printer_status():
    """Verifica o status da impressora."""
    # Simulação de status da impressora
    return {"is_connected": True} 