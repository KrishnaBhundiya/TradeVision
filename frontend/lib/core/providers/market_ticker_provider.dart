import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/stock_data.dart';
import '../../services/api_service.dart';

class MarketTickerNotifier extends ChangeNotifier {
  late List<StockModel> _stocks;
  final Map<String, int> _tickDirections = {}; // 1 for up, -1 for down, 0 for none
  Timer? _timer;
  final Random _random = Random();

  List<Map<String, dynamic>> _gainers = [];
  List<Map<String, dynamic>> _losers = [];

  List<Map<String, dynamic>> _indices = [
    {'name': 'NIFTY 50',    'value': 23242.40, 'change': 24.80, 'changePercent': 0.11, 'up': true},
    {'name': 'SENSEX',      'value': 74336.45, 'change': 332.63, 'changePercent': 0.45, 'up': true},
    {'name': 'NIFTY BANK',  'value': 56262.40, 'change': -30.05, 'changePercent': -0.05, 'up': false},
    {'name': 'NIFTY IT',    'value': 28833.05, 'change': -254.60, 'changePercent': -0.88, 'up': false},
    {'name': 'NIFTY NEXT 50','value': 72145.10, 'change': 310.20, 'changePercent': 0.43, 'up': true},
  ];

  MarketTickerNotifier() {
    _stocks = List<StockModel>.from(StockRepository.stocks);
    _startLiveTicks();
    hydrateLiveMarket();
  }

  List<StockModel> get stocks => _stocks;
  List<Map<String, dynamic>> get indices => _indices;
  List<Map<String, dynamic>> get gainers => _gainers;
  List<Map<String, dynamic>> get losers => _losers;

  Future<void> hydrateLiveMarket() async {
    try {
      // 1. Fetch real exchange indices
      final liveIndices = await ApiService.fetchLiveIndices();
      if (liveIndices.isNotEmpty) {
        _indices = liveIndices.map((idx) => {
          'name': idx['name'] ?? '',
          'value': (idx['price'] as num?)?.toDouble() ?? 0.0,
          'change': (idx['change'] as num?)?.toDouble() ?? 0.0,
          'changePercent': (idx['changePercent'] as num?)?.toDouble() ?? 0.0,
          'up': idx['isPositive'] ?? true,
        }).toList();
        notifyListeners();
      }

      // 2. Fetch real live top movers (gainers & losers)
      final movers = await ApiService.fetchLiveMovers();
      if (movers != null) {
        if (movers['gainers'] is List && (movers['gainers'] as List).isNotEmpty) {
          _gainers = List<Map<String, dynamic>>.from(movers['gainers']);
        }
        if (movers['losers'] is List && (movers['losers'] as List).isNotEmpty) {
          _losers = List<Map<String, dynamic>>.from(movers['losers']);
        }
        notifyListeners();
      }

      // 3. Hydrate top benchmark stocks for watchlist
      final topTickers = ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'BAJFINANCE', 'ICICIBANK', 'SBIN', 'TATAMOTORS'];
      for (final t in topTickers) {
        final q = await ApiService.fetchLiveQuote(t);
        if (q != null && q['current_price'] != null) {
          final model = StockModel.fromMasterJson(q);
          StockRepository.registerStock(model);
          final idx = _stocks.indexWhere((s) => s.ticker == t);
          if (idx != -1) {
            _stocks[idx] = model;
          } else {
            _stocks.add(model);
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }


  int getTickDirection(String ticker) {
    return _tickDirections[ticker] ?? 0;
  }

  void _startLiveTicks() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _tickRandomStock();
    });
  }

  void _tickRandomStock() {
    if (_stocks.isEmpty) return;

    final index = _random.nextInt(_stocks.length);
    final stock = _stocks[index];

    final isUp = _random.nextBool();
    final deltaPercent = (_random.nextDouble() * 0.25 + 0.05) * (isUp ? 1 : -1);
    final oldPrice = stock.price;
    final newPrice = oldPrice * (1 + deltaPercent / 100);
    final newChangePercent = stock.changePercent + deltaPercent;

    final updatedChart1D = List<FlSpot>.from(stock.chart1D);
    if (updatedChart1D.isNotEmpty) {
      final lastSpot = updatedChart1D.last;
      updatedChart1D.add(FlSpot(lastSpot.x + 0.5, newPrice));
      if (updatedChart1D.length > 25) {
        updatedChart1D.removeAt(0);
      }
    }

    _stocks[index] = stock.copyWith(
      price: newPrice,
      changePercent: newChangePercent,
      chart1D: updatedChart1D,
    );

    _tickDirections[stock.ticker] = isUp ? 1 : -1;
    _updateIndices();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      _tickDirections[stock.ticker] = 0;
      notifyListeners();
    });
  }

  void _updateIndices() {
    final idxIndex = _random.nextInt(_indices.length);
    final idx = _indices[idxIndex];
    final isUp = _random.nextBool();
    final delta = (_random.nextDouble() * 14.0 + 2.0) * (isUp ? 1 : -1);

    final double oldVal = (idx['value'] as num).toDouble();
    final double newVal = oldVal + delta;
    final double oldChange = (idx['change'] as num).toDouble();
    final double newChange = oldChange + delta;
    final double newPercent = (newChange / (newVal - newChange)) * 100;

    _indices[idxIndex] = {
      'name': idx['name'],
      'value': newVal,
      'change': newChange,
      'changePercent': newPercent,
      'up': newChange >= 0,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
