# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.news import NewsResponse
from app.services.news_service import get_news_by_symbol

router = APIRouter(prefix="/news", tags=["news"])

@router.get("/{symbol}", response_model=NewsResponse)
def get_news(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_news_by_symbol(clean_symbol)

    if not result["articles"]:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="News not found")

    return result