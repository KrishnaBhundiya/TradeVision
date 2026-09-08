# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.stock_detail import StockDetailResponse
from app.services.stock_detail_service import get_stock_detail_by_symbol

router = APIRouter(prefix="/stock-details", tags=["stock-details"])

@router.get("/{symbol}", response_model=StockDetailResponse)
def get_stock_details(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_stock_detail_by_symbol(clean_symbol)

    if result["status"] == "not_found":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Stock detail not found")

    return result