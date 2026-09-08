# pyrefly: ignore [missing-import]
from fastapi import APIRouter, HTTPException, status
from app.schemas.recommendation import RecommendationResponse
from app.services.recommendation_service import get_recommendation_by_symbol

router = APIRouter(prefix="/recommendation", tags=["recommendation"])

@router.get("/{symbol}", response_model=RecommendationResponse)
def get_recommendation(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    if not clean_symbol:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid symbol")

    result = get_recommendation_by_symbol(clean_symbol)

    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recommendation not found")

    return result