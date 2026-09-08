# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.chart import ChartResponse
from app.services.chart_service import get_chart_by_symbol

router = APIRouter(prefix="/chart", tags=["chart"])

@router.get("/{symbol}", response_model=ChartResponse)
def get_chart(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_chart_by_symbol(clean_symbol)

    if not result["points"]:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chart data not found")

    return result
