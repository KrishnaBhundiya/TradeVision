def get_news_by_symbol(symbol: str):
    clean_symbol = symbol.strip().upper() if symbol else ""
    data = {
        "AAPL": {
            "symbol": "AAPL",
            "articles": [
                {
                    "title": "Apple expands AI features in latest update",
                    "source": "MarketWatch",
                    "url": "https://example.com/apple-ai",
                    "published_at": "2026-07-16"
                },
                {
                    "title": "Apple stock remains strong after earnings",
                    "source": "Reuters",
                    "url": "https://example.com/apple-earnings",
                    "published_at": "2026-07-15"
                }
            ],
            "message": "News loaded"
        },
        "TSLA": {
            "symbol": "TSLA",
            "articles": [
                {
                    "title": "Tesla delivery outlook improves",
                    "source": "CNBC",
                    "url": "https://example.com/tesla-delivery",
                    "published_at": "2026-07-16"
                },
                {
                    "title": "Tesla shares move on market sentiment",
                    "source": "Bloomberg",
                    "url": "https://example.com/tesla-sentiment",
                    "published_at": "2026-07-15"
                }
            ],
            "message": "News loaded"
        }
    }

    return data.get(clean_symbol, {
        "symbol": clean_symbol,
        "articles": [],
        "message": "News not found"
    })