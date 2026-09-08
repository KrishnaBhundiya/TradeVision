# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.stock import StockResponse
from app.services.stock_service import get_stock_by_symbol

router = APIRouter(prefix="/stocks", tags=["stocks"])

@router.get("/{symbol}", response_model=StockResponse)
def read_stock(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_stock_by_symbol(clean_symbol)

    if result["status"] == "not_found":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Stock not found")

    return result