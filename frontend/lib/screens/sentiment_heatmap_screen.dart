import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/market_ticker_provider.dart';
import '../core/data/stock_data.dart';

class SentimentHeatmapScreen extends StatefulWidget {
  const SentimentHeatmapScreen({super.key});

  @override
  State<SentimentHeatmapScreen> createState() => _SentimentHeatmapScreenState();
}

class _SentimentHeatmapScreenState extends State<SentimentHeatmapScreen> {
  String _filter = 'ALL'; // ALL, BULLISH, NEUTRAL, BEARISH

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch ticker updates so prices and sentiment heatmaps stay live
    context.watch<MarketTickerNotifier>();

    // Take top 50 stocks from repository
    final allStocks = StockRepository.stocks.take(50).toList();

    // Calculate aggregated sentiment distribution
    int bullishCount = 0;
    int bearishCount = 0;
    int neutralCount = 0;

    for (final s in allStocks) {
      if (s.changePercent > 0.4 || s.aiSignal.contains('BUY')) {
        bullishCount++;
      } else if (s.changePercent < -0.4 || s.aiSignal.contains('SELL')) {
        bearishCount++;
      } else {
        neutralCount++;
      }
    }

    final total = allStocks.isEmpty ? 1 : allStocks.length;
    final bullPct = (bullishCount / total) * 100;
    final bearPct = (bearishCount / total) * 100;

    final filteredStocks = allStocks.where((s) {
      final isBull = s.changePercent > 0.4 || s.aiSignal.contains('BUY');
      final isBear = s.changePercent < -0.4 || s.aiSignal.contains('SELL');
      if (_filter == 'BULLISH') return isBull;
      if (_filter == 'BEARISH') return isBear;
      if (_filter == 'NEUTRAL') return !isBull && !isBear;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF00C853),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Live Sentiment Heatmap',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Market Breadth Bar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MARKET SENTIMENT BREADTH (TOP 50)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8892A4),
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bullPct >= 50 ? 'NET BULLISH' : 'NET CAUTIOUS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: bullPct >= 50
                                ? const Color(0xFF00C853)
                                : const Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          Expanded(
                            flex: bullishCount.clamp(1, 50),
                            child: Container(color: const Color(0xFF00C853)),
                          ),
                          Expanded(
                            flex: neutralCount.clamp(1, 50),
                            child: Container(color: const Color(0xFFFF8C00)),
                          ),
                          Expanded(
                            flex: bearishCount.clamp(1, 50),
                            child: Container(color: const Color(0xFFFF3B3B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _legendDot(
                        color: const Color(0xFF00C853),
                        label: 'Bullish $bullishCount (${bullPct.toStringAsFixed(0)}%)',
                      ),
                      _legendDot(
                        color: const Color(0xFFFF8C00),
                        label: 'Neutral $neutralCount',
                      ),
                      _legendDot(
                        color: const Color(0xFFFF3B3B),
                        label: 'Bearish $bearishCount (${bearPct.toStringAsFixed(0)}%)',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Filter Chips ───────────────────────────────────────
            Row(
              children: [
                _filterChip('ALL', 'All (50)', isDark),
                const SizedBox(width: 8),
                _filterChip('BULLISH', 'Bullish ($bullishCount)', isDark),
                const SizedBox(width: 8),
                _filterChip('NEUTRAL', 'Neutral ($neutralCount)', isDark),
                const SizedBox(width: 8),
                _filterChip('BEARISH', 'Bearish ($bearishCount)', isDark),
              ],
            ),
            const SizedBox(height: 16),

            // ── Grid of 50 Stocks ──────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStocks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.15,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, idx) {
                final s = filteredStocks[idx];
                final isPositive = s.changePercent >= 0;
                final absChange = s.changePercent.abs();

                // Compute gradient color based on intensity
                final tileColor = isPositive
                    ? (absChange > 1.5
                        ? const Color(0xFF008837)
                        : (absChange > 0.5 ? const Color(0xFF00A844) : const Color(0xFF1E3A2B)))
                    : (absChange > 1.5
                        ? const Color(0xFFB91C1C)
                        : (absChange > 0.5 ? const Color(0xFFDC2626) : const Color(0xFF3B1E22)));

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/stock/${s.ticker}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: tileColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.ticker,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${s.price.toStringAsFixed(1)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isPositive ? "+" : ""}${s.changePercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8892A4)),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0066CC)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF8892A4),
          ),
        ),
      ),
    );
  }
}
