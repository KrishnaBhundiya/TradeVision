from contextlib import asynccontextmanager
# pyrefly: ignore [missing-import]
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from app.database import init_db
from app.routers.auth import router as auth_router
from app.routers.chart import router as chart_router
from app.routers.indicators import router as indicators_router
from app.routers.news import router as news_router
from app.routers.overview import router as overview_router
from app.routers.recommendation import router as recommendation_router
from app.routers.stock_details import router as stock_details_router
from app.routers.stocks import router as stocks_router
from app.routers.test import router as test_router
from app.routers.watchlist import router as watchlist_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB tables on application startup
    await init_db()
    yield

app = FastAPI(title="TradeVision AI Backend", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(test_router)
app.include_router(auth_router)
app.include_router(watchlist_router)
app.include_router(stock_details_router)
app.include_router(chart_router)
app.include_router(indicators_router)
app.include_router(news_router)
app.include_router(overview_router)
app.include_router(recommendation_router)
app.include_router(stocks_router)

@app.get("/")
def root():
    return {"message": "TradeVision AI backend is running"}

@app.get("/health")
def health():
    return {"status": "ok"}