# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.overview import OverviewResponse
from app.services.overview_service import get_overview_by_symbol

router = APIRouter(prefix="/overview", tags=["overview"])

@router.get("", response_model=OverviewResponse)
@router.get("/", response_model=OverviewResponse, include_in_schema=False)
def get_overview(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_overview_by_symbol(clean_symbol)

    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Overview data not found")

    return result