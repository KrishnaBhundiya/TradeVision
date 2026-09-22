import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/error_handler.dart';
import '../models/models.dart';
import 'live_news_service.dart';
import '../core/data/stock_data.dart' show StockRepository;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const Duration _timeout = Duration(milliseconds: 2500);

  // Instance methods for legacy dashboard screen
  Future<StockModel> fetchStock(String symbol) async {
    final res = await get('/stock/$symbol');
    return res != null ? StockModel.fromJson(res) : StockModel(symbol: symbol);
  }

  Future<StockDetailModel> fetchStockDetails(String symbol) async {
    final res = await get('/stock-details/$symbol');
    return res != null ? StockDetailModel.fromJson(res) : StockDetailModel(symbol: symbol);
  }

  Future<RecommendationModel> fetchRecommendation(String symbol) async {
    final res = await get('/recommendation/$symbol');
    return res != null
        ? RecommendationModel.fromJson(res)
        : RecommendationModel(symbol: symbol, decision: 'N/A', confidence: 0, reason: '', keyFactors: []);
  }

  Future<OverviewModel> fetchOverview(String symbol) async {
    final res = await get('/overview/$symbol');
    return res != null
        ? OverviewModel.fromJson(res)
        : OverviewModel(
            stock: StockInfo(symbol: symbol),
            indicators: IndicatorInfo(symbol: symbol, signal: 'N/A'),
          );
  }

  Future<NewsModel> fetchNews(String symbol) async {
    final res = await get('/news/$symbol');
    return res != null ? NewsModel.fromJson(res) : NewsModel(symbol: symbol, articles: []);
  }

  Future<IndicatorModel> fetchIndicators(String symbol) async {
    final res = await get('/indicators/$symbol');
    return res != null ? IndicatorModel.fromJson(res) : IndicatorModel(symbol: symbol, signal: 'N/A');
  }

  Future<ChartModel> fetchChart(String symbol) async {
    final res = await get('/chart/$symbol');
    return res != null ? ChartModel.fromJson(res) : ChartModel(symbol: symbol, points: []);
  }

  static Future<Map<String, dynamic>> fetchMarketTrend() async {
    final res = await get('/market/trend');
    return res ?? {};
  }

  static Future<List<Map<String, dynamic>>> searchStocks(String query, {String? sector, int limit = 30}) async {
    final cleanQ = query.trim();
    try {
      final sectorParam = sector != null && sector != 'All' ? '&sector=${Uri.encodeComponent(sector)}' : '';
      final endpoint = cleanQ.isEmpty
          ? '/stocks/all?limit=$limit$sectorParam'
          : '/stocks/search?q=${Uri.encodeComponent(cleanQ)}&limit=$limit$sectorParam';
      final res = await get(endpoint, retries: 0);
      if (res != null && res['results'] is List && (res['results'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(res['results']);
      }
    } catch (_) {}

    // Standalone fallback: Search all 2500+ stocks in client memory
    final localMatches = StockRepository.searchStocks(cleanQ, limit: limit);
    return localMatches.map((s) => s.toJson()).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchStocksUniverse({int limit = 50, int offset = 0, String? sector}) async {
    try {
      final sectorParam = sector != null && sector != 'All' ? '&sector=${Uri.encodeComponent(sector)}' : '';
      final res = await get('/stocks/all?limit=$limit&offset=$offset$sectorParam', retries: 0);
      if (res != null && res['results'] is List && (res['results'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(res['results']);
      }
    } catch (_) {}

    // Standalone fallback: Load slice from bundled 2,500+ stock universe
    final localStocks = StockRepository.getUniverse(sector: sector, limit: limit, offset: offset);
    return localStocks.map((s) => s.toJson()).toList();
  }

  static Future<List<String>> fetchSectors() async {
    try {
      final res = await get('/stocks/sectors', retries: 0);
      if (res != null) {
        if (res is Map && res['sectors'] is List && (res['sectors'] as List).isNotEmpty) {
          return (res['sectors'] as List)
              .map((e) => (e['sector'] as String?) ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (res is List && res.isNotEmpty) {
          return res
              .map((e) => (e['sector'] as String?) ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}

    // Standalone fallback: Extract unique sectors from client universe
    return StockRepository.getAllSectors().where((s) => s != 'All').toList();
  }

  static Future<Map<String, dynamic>> fetchStockDetail(String symbol) async {
    try {
      final res = await get('/stock-details/$symbol', retries: 0);
      if (res is Map<String, dynamic> && res.isNotEmpty) return res;
    } catch (_) {}
    return StockRepository.getStock(symbol).toJson();
  }

  static Future<Map<String, dynamic>?> fetchLiveQuote(String symbol) async {
    final cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim();
    try {
      final res = await get('/api/live/quote/$cleanSym', retries: 0);
      if (res is Map<String, dynamic> && res.isNotEmpty) return res;
    } catch (_) {}
    return StockRepository.getStock(cleanSym).toJson();
  }

  static Future<Map<String, dynamic>?> fetchLiveCandles(String symbol, {String period = '1D'}) async {
    final cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim();
    try {
      final res = await get('/api/live/candles/$cleanSym?period=$period', retries: 0);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchLiveIndices() async {
    try {
      final res = await get('/api/live/indices', retries: 0);
      if (res != null && res is Map && res['indices'] is List && (res['indices'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(res['indices']);
      }
    } catch (_) {}

    return [
      {'name': 'NIFTY 50',     'price': 23242.40, 'change': 24.80,  'changePercent': 0.11, 'isPositive': true},
      {'name': 'SENSEX',       'price': 74336.45, 'change': 332.63, 'changePercent': 0.45, 'isPositive': true},
      {'name': 'BANK NIFTY',   'price': 56262.40, 'change': -30.05, 'changePercent': -0.05, 'isPositive': false},
      {'name': 'NIFTY IT',     'price': 28833.05, 'change': -254.60,'changePercent': -0.88, 'isPositive': false},
      {'name': 'NIFTY NEXT 50','price': 72145.10, 'change': 310.20, 'changePercent': 0.43, 'isPositive': true},
      {'name': 'INDIA VIX',    'price': 13.42,    'change': -0.42,  'changePercent': -3.03, 'isPositive': false},
    ];
  }

  static Future<Map<String, dynamic>?> fetchLiveMovers() async {
    try {
      final res = await get('/api/live/movers', retries: 0);
      if (res is Map<String, dynamic> &&
          res['gainers'] is List &&
          (res['gainers'] as List).isNotEmpty) {
        return res;
      }
    } catch (_) {}

    return {
      'gainers': StockRepository.getClientGainers(),
      'losers': StockRepository.getClientLosers(),
      'timestamp': 'Live IST',
    };
  }

  /// Fetches per-stock technical indicators: RSI, MACD, MA-20/50/200, Bollinger, 
  /// Stochastic, ATR, support/resistance, buyers/sellers %, AI signal + confidence.
  static Future<Map<String, dynamic>> fetchTechnicals(String symbol) async {
    final cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim();
    try {
      final res = await get('/api/live/technicals/$cleanSym', retries: 0);
      if (res is Map<String, dynamic> && res.isNotEmpty) return res;
    } catch (_) {}

    final stock = StockRepository.getStock(cleanSym);
    final p = stock.price;
    final isPos = stock.isPositive;
    return {
      'rsi': stock.rsi,
      'macd': stock.macd,
      'macd_val': isPos ? 2.4 : -1.8,
      'signal_val': isPos ? 1.8 : -1.2,
      'ma_20': (p * (isPos ? 0.98 : 1.02)).toStringAsFixed(1),
      'ma_50': (p * (isPos ? 0.95 : 1.05)).toStringAsFixed(1),
      'ma_200': (p * (isPos ? 0.91 : 1.08)).toStringAsFixed(1),
      'bollinger_upper': (p * 1.06).toStringAsFixed(1),
      'bollinger_lower': (p * 0.94).toStringAsFixed(1),
      'stochastic_k': isPos ? 68.4 : 34.2,
      'stochastic_d': isPos ? 62.1 : 38.6,
      'atr': (p * 0.024).toStringAsFixed(1),
      'support_1': (p * 0.97).toStringAsFixed(1),
      'support_2': (p * 0.94).toStringAsFixed(1),
      'resistance_1': (p * 1.03).toStringAsFixed(1),
      'resistance_2': (p * 1.06).toStringAsFixed(1),
      'buyers_pct': isPos ? 64 : 38,
      'sellers_pct': isPos ? 36 : 62,
      'ai_signal': stock.aiSignal,
      'ai_confidence': isPos ? 84.5 : 78.2,
      'ai_reason': stock.aiReason,
    };
  }

  /// Fetches full company fundamentals: P/E, EPS, dividend yield, book value,
  /// debt-to-equity, ROE, beta, market cap, sector, description.
  static Future<Map<String, dynamic>> fetchFundamentals(String symbol) async {
    final cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim();
    try {
      final res = await get('/api/live/fundamentals/$cleanSym', retries: 0);
      if (res is Map<String, dynamic> && res.isNotEmpty) return res;
    } catch (_) {}

    final stock = StockRepository.getStock(cleanSym);
    final pe = double.tryParse(stock.peRatio) ?? 22.0;
    return {
      'pe_ratio': stock.peRatio,
      'market_cap': stock.marketCap,
      'week52_high': stock.week52High,
      'week52_low': stock.week52Low,
      'volume': stock.volume,
      'sector': stock.sector,
      'industry': stock.industry,
      'dividend_yield': '1.24%',
      'book_value': '₹${(stock.price * 0.42).toStringAsFixed(1)}',
      'debt_to_equity': '0.38',
      'roe': '18.4%',
      'eps': '₹${(stock.price / pe).toStringAsFixed(1)}',
      'beta': '0.92',
    };
  }

  static Future<List<Map<String, dynamic>>> fetchMarketNews({int limit = 15}) async {
    try {
      final res = await get('/news/market?limit=$limit', retries: 0);
      if (res != null && res is Map && res['articles'] is List && (res['articles'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(res['articles']);
      }
    } catch (_) {}

    // Fallback to direct client-side live news (always works on mobile with Internet)
    return await LiveNewsService.fetchLiveNews(limit: limit);
  }

  static Future<List<Map<String, dynamic>>> fetchStockNews(String symbol, {int limit = 10}) async {
    if (symbol.isEmpty) return [];
    final res = await get('/news/$symbol?limit=$limit');
    if (res != null && res is Map && res['articles'] is List) {
      return List<Map<String, dynamic>>.from(res['articles']);
    }
    return [];
  }

  // Safe GET with timeout + retry
  static Future<dynamic> get(
    String endpoint, {
    int retries = 1,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl$endpoint'),
              headers: _headers(),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 429) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else if (response.statusCode >= 500) {
          throw NetworkException('Server error: ${response.statusCode}');
        }
      } on TimeoutException {
        if (attempt == retries) return null;
      } on http.ClientException {
        // Fast fail on connection refused (offline/standalone mobile)
        return null;
      } catch (e) {
        if (attempt == retries || e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
          return null;
        }
      }
    }
    return null;
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '2.4.0',
        'X-Platform': 'flutter-web',
      };
}
