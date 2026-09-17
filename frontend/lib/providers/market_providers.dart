import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';

/// Provider for Market Overview & Trend Indices
final marketTrendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiService.fetchMarketTrend();
});

/// Provider for Stock Search Queries
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

final stockSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(stockSearchQueryProvider);
  return await ApiService.searchStocks(query);
});

/// Provider for Selected Stock Detail
final selectedStockSymbolProvider = StateProvider<String>((ref) => 'RELIANCE.NS');

final stockDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final symbol = ref.watch(selectedStockSymbolProvider);
  return await ApiService.fetchStockDetail(symbol);
});

/// Provider for Live Real-Time Indian Market News streaming every 1 second
final marketNewsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  // 1. Fetch & yield immediate REST data
  try {
    final initial = await ApiService.fetchMarketNews(limit: 20);
    if (initial.isNotEmpty) {
      yield initial;
    }
  } catch (_) {}

  // 2. Stream live updates every second via WebSocket with continuous 1-second auto-refresh
  final controller = StreamController<List<Map<String, dynamic>>>();
  WebSocketChannel? channel;
  Timer? pollTimer;

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final fresh = await ApiService.fetchMarketNews(limit: 20);
        if (fresh.isNotEmpty && !controller.isClosed) {
          controller.add(fresh);
        }
      } catch (_) {}
    });
  }

  void connectWs() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8000/ws/news'));
      channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            if (json is Map<String, dynamic> && json['articles'] is List) {
              final list = List<Map<String, dynamic>>.from(json['articles']);
              if (!controller.isClosed && list.isNotEmpty) {
                controller.add(list);
              }
            }
          } catch (_) {}
        },
        onError: (_) => startPolling(),
        onDone: () => startPolling(),
        cancelOnError: true,
      );
    } catch (_) {
      startPolling();
    }
  }

  connectWs();

  ref.onDispose(() {
    channel?.sink.close();
    pollTimer?.cancel();
    controller.close();
  });

  yield* controller.stream;
});

/// Provider for Stock-Specific News
final stockNewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, symbol) async {
  return await ApiService.fetchStockNews(symbol, limit: 10);
});
