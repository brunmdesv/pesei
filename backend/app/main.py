from fastapi import FastAPI
from .balance import router as balance_router
from .printer import router as printer_router
from .printer_config import router as printer_config_router
from .db import init_db, get_connection
from .models import Price

# Inicialização do app
app = FastAPI()

# Inicializa o banco de dados
init_db()

# Inclui as rotas dos módulos
app.include_router(balance_router)
app.include_router(printer_router)
app.include_router(printer_config_router)

# Rotas administrativas
@app.get("/admin/price")
def read_price():
    """Retorna o valor do kg armazenado no banco."""
    conn = get_connection()
    row = conn.execute("SELECT value FROM config WHERE key='price_per_kg'").fetchone()
    conn.close()
    return {"price_per_kg": float(row["value"])}

@app.post("/admin/price")
def update_price(p: Price):
    """Atualiza o valor do kg no banco."""
    conn = get_connection()
    conn.execute("UPDATE config SET value = ? WHERE key='price_per_kg'", (str(p.price_per_kg),))
    conn.commit()
    conn.close()
    return {"status": "ok", "price_per_kg": p.price_per_kg}
