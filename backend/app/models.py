from pydantic import BaseModel

class Price(BaseModel):
    price_per_kg: float
