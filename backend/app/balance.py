import asyncio
import random
import datetime
from fastapi import APIRouter

# Criação do roteador FastAPI para modularização
router = APIRouter()

@router.get("/weight")
async def get_weight():
    """Simula a leitura de peso de uma balança."""
    # Peso inicial aleatório (0 a 5 kg)
    peso = random.uniform(0.1, 5.0)
    print(f"[Simulação] Peso inicial: {peso:.3f} kg")

    # Simular estabilização do peso (~2 segundos)
    await asyncio.sleep(2)

    # Peso estabilizado (fixado para a simulação)
    peso_estabilizado = round(peso, 3)
    print(f"[Simulação] Peso estabilizado: {peso_estabilizado:.3f} kg")

    # Retornar o peso e o timestamp
    return {
        "weight": peso_estabilizado,
        "timestamp": datetime.datetime.now().isoformat()
    }
