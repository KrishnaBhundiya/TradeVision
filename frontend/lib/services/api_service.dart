import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<String> fetchBackendMessage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']?.toString() ?? 'No message found';
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch backend: $e');
    }
  }

  Future<StockModel> fetchStock(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/stocks/$symbol'));
    if (response.statusCode == 200) {
      return StockModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch stock for $symbol: ${response.statusCode}');
    }
  }

  Future<StockDetailModel> fetchStockDetails(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/stock-details/$symbol'));
    if (response.statusCode == 200) {
      return StockDetailModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch stock details for $symbol: ${response.statusCode}');
    }
  }

  Future<RecommendationModel> fetchRecommendation(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/recommendation/$symbol'));
    if (response.statusCode == 200) {
      return RecommendationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch recommendation for $symbol: ${response.statusCode}');
    }
  }

  Future<OverviewModel> fetchOverview(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/overview?symbol=$symbol'));
    if (response.statusCode == 200) {
      return OverviewModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch overview for $symbol: ${response.statusCode}');
    }
  }

  Future<NewsModel> fetchNews(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/news/$symbol'));
    if (response.statusCode == 200) {
      return NewsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch news for $symbol: ${response.statusCode}');
    }
  }

  Future<IndicatorModel> fetchIndicators(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/indicators?symbol=$symbol'));
    if (response.statusCode == 200) {
      return IndicatorModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch indicators for $symbol: ${response.statusCode}');
    }
  }

  Future<ChartModel> fetchChart(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/chart/$symbol'));
    if (response.statusCode == 200) {
      return ChartModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch chart data for $symbol: ${response.statusCode}');
    }
  }
}