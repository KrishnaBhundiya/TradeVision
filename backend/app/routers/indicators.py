# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.indicator import IndicatorResponse
from app.services.indicator_service import get_indicator_by_symbol

router = APIRouter(prefix="/indicators", tags=["indicators"])

@router.get("", response_model=IndicatorResponse)
@router.get("/", response_model=IndicatorResponse, include_in_schema=False)
def get_indicators(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_indicator_by_symbol(clean_symbol)

    if result["signal"] == "not_found":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Indicator data not found")

    return result