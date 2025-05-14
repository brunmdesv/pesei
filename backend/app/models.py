from pydantic import BaseModel
from datetime import datetime

class Price(BaseModel):
    price_per_kg: float

class Ticket(BaseModel):
    weight: float
    total_value: str
    timestamp: str

class WeightRecord(BaseModel):
    id: int | None = None
    weight: float
    total_value: float
    timestamp: datetime
    printed: bool = True
