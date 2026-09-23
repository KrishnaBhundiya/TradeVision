import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/stock_data.dart';

class PaperTrade {
  final String id;
  final String ticker;
  final String stockName;
  final bool isBuy;
  final int quantity;
  final double price;
  final DateTime timestamp;
  final double realizedPnL;

  PaperTrade({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.isBuy,
    required this.quantity,
    required this.price,
    DateTime? timestamp,
    this.realizedPnL = 0.0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'stockName': stockName,
    'isBuy': isBuy,
    'quantity': quantity,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'realizedPnL': realizedPnL,
  };

  factory PaperTrade.fromJson(Map<String, dynamic> map) => PaperTrade(
    id: map['id'] ?? '',
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    isBuy: map['isBuy'] ?? true,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
    realizedPnL: (map['realizedPnL'] as num?)?.toDouble() ?? 0.0,
  );
}

class PaperPosition {
  final String ticker;
  final String stockName;
  int quantity;
  double avgPrice;
  double totalInvested;

  PaperPosition({
    required this.ticker,
    required this.stockName,
    required this.quantity,
    required this.avgPrice,
    required this.totalInvested,
  });

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'stockName': stockName,
    'quantity': quantity,
    'avgPrice': avgPrice,
    'totalInvested': totalInvested,
  };

  factory PaperPosition.fromJson(Map<String, dynamic> map) => PaperPosition(
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    avgPrice: (map['avgPrice'] as num?)?.toDouble() ?? 0.0,
    totalInvested: (map['totalInvested'] as num?)?.toDouble() ?? 0.0,
  );
}

class PortfolioProvider extends ChangeNotifier {
  static const double initialCapital = 100000.0; // ₹1,00,000 starting paper capital
  static const String _storageKeyCash = 'tradevision_paper_cash_v2';
  static const String _storageKeyPositions = 'tradevision_paper_positions_v2';
  static const String _storageKeyTrades = 'tradevision_paper_trades_v2';
  static const String _storageKeyRealized = 'tradevision_paper_realized_v2';

  double _virtualCash = initialCapital;
  final Map<String, PaperPosition> _positions = {};
  final List<PaperTrade> _tradeHistory = [];
  double _realizedPnL = 0.0;
  final List<StockModel> _watchlist = List.from(StockRepository.stocks);

  PortfolioProvider() {
    _loadFromPrefs();
  }

  double get virtualCash => _virtualCash;
  double get realizedPnL => _realizedPnL;
  List<PaperTrade> get tradeHistory => List.unmodifiable(_tradeHistory);
  Map<String, PaperPosition> get positions => _positions;
  List<StockModel> get watchlist => _watchlist;

  // Legacy compatibility getters for existing screens
  Map<String, int> get holdings => _positions.map((k, v) => MapEntry(k, v.quantity));
  
  double get totalInvested {
    double sum = 0.0;
    _positions.forEach((_, pos) => sum += pos.totalInvested);
    return sum;
  }

  double get totalCurrentValue {
    double sum = 0.0;
    _positions.forEach((ticker, pos) {
      final stock = StockRepository.getStock(ticker);
      sum += stock.price * pos.quantity;
    });
    return sum;
  }

  double get totalPortfolioValue => _virtualCash + totalCurrentValue;

  double getPnL() {
    return totalCurrentValue - totalInvested;
  }

  double getPnLPercent() {
    if (totalInvested <= 0) return 0.0;
    return (getPnL() / totalInvested) * 100;
  }

  int getHoldingQuantity(String ticker) {
    return _positions[ticker.toUpperCase()]?.quantity ?? 0;
  }

  double getHoldingAvgPrice(String ticker) {
    return _positions[ticker.toUpperCase()]?.avgPrice ?? 0.0;
  }

  int get winningTradesCount =>
      _tradeHistory.where((t) => !t.isBuy && t.realizedPnL > 0).length;

  int get losingTradesCount =>
      _tradeHistory.where((t) => !t.isBuy && t.realizedPnL < 0).length;

  double get winRate {
    final closedTrades = winningTradesCount + losingTradesCount;
    if (closedTrades == 0) return 0.0;
    return (winningTradesCount / closedTrades) * 100;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_storageKeyCash)) {
        _virtualCash = prefs.getDouble(_storageKeyCash) ?? initialCapital;
      }
      if (prefs.containsKey(_storageKeyRealized)) {
        _realizedPnL = prefs.getDouble(_storageKeyRealized) ?? 0.0;
      }
      final posRaw = prefs.getString(_storageKeyPositions);
      if (posRaw != null && posRaw.isNotEmpty) {
        final decoded = jsonDecode(posRaw) as Map<String, dynamic>;
        _positions.clear();
        decoded.forEach((k, v) {
          _positions[k] = PaperPosition.fromJson(Map<String, dynamic>.from(v));
        });
      }
      final tradesRaw = prefs.getString(_storageKeyTrades);
      if (tradesRaw != null && tradesRaw.isNotEmpty) {
        final list = jsonDecode(tradesRaw) as List;
        _tradeHistory.clear();
        for (final item in list) {
          _tradeHistory.add(PaperTrade.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[PortfolioProvider] Load error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_storageKeyCash, _virtualCash);
      await prefs.setDouble(_storageKeyRealized, _realizedPnL);
      await prefs.setString(
        _storageKeyPositions,
        jsonEncode(_positions.map((k, v) => MapEntry(k, v.toJson()))),
      );
      await prefs.setString(
        _storageKeyTrades,
        jsonEncode(_tradeHistory.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[PortfolioProvider] Save error: $e');
    }
  }

  void buyStock(StockModel stock, int qty) {
    if (qty <= 0) return;
    final ticker = stock.ticker.toUpperCase();
    final cost = stock.price * qty;

    if (cost > _virtualCash) {
      return; // Insufficient virtual balance
    }

    _virtualCash -= cost;

    if (_positions.containsKey(ticker)) {
      final existing = _positions[ticker]!;
      final newQty = existing.quantity + qty;
      final newInvested = existing.totalInvested + cost;
      existing.quantity = newQty;
      existing.totalInvested = newInvested;
      existing.avgPrice = newInvested / newQty;
    } else {
      _positions[ticker] = PaperPosition(
        ticker: ticker,
        stockName: stock.fullName,
        quantity: qty,
        avgPrice: stock.price,
        totalInvested: cost,
      );
    }

    _tradeHistory.insert(
      0,
      PaperTrade(
        id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
        ticker: ticker,
        stockName: stock.fullName,
        isBuy: true,
        quantity: qty,
        price: stock.price,
      ),
    );

    _saveToPrefs();
    notifyListeners();
  }

  void sellStock(StockModel stock, int qty) {
    final ticker = stock.ticker.toUpperCase();
    if (!_positions.containsKey(ticker) || qty <= 0) return;

    final pos = _positions[ticker]!;
    if (qty > pos.quantity) return;

    final revenue = stock.price * qty;
    final costBasis = pos.avgPrice * qty;
    final tradePnL = revenue - costBasis;

    _virtualCash += revenue;
    _realizedPnL += tradePnL;

    pos.quantity -= qty;
    pos.totalInvested -= costBasis;

    if (pos.quantity <= 0) {
      _positions.remove(ticker);
    }

    _tradeHistory.insert(
      0,
      PaperTrade(
        id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
        ticker: ticker,
        stockName: stock.fullName,
        isBuy: false,
        quantity: qty,
        price: stock.price,
        realizedPnL: tradePnL,
      ),
    );

    _saveToPrefs();
    notifyListeners();
  }

  void resetPortfolio() {
    _virtualCash = initialCapital;
    _positions.clear();
    _tradeHistory.clear();
    _realizedPnL = 0.0;
    _saveToPrefs();
    notifyListeners();
  }

  bool isWatchlisted(String ticker) {
    return _watchlist.any((s) => s.ticker.toUpperCase() == ticker.toUpperCase());
  }

  void toggleWatchlist(StockModel stock) {
    if (isWatchlisted(stock.ticker)) {
      _watchlist.removeWhere((s) => s.ticker.toUpperCase() == stock.ticker.toUpperCase());
    } else {
      _watchlist.add(stock);
    }
    notifyListeners();
  }
}
