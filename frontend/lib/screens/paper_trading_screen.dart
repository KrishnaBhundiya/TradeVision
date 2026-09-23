import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/portfolio_provider.dart';
import '../core/providers/market_ticker_provider.dart';
import '../core/data/stock_data.dart';
import '../widgets/ticker_logo.dart';

class PaperTradingScreen extends StatefulWidget {
  const PaperTradingScreen({super.key});

  @override
  State<PaperTradingScreen> createState() => _PaperTradingScreenState();
}

class _PaperTradingScreenState extends State<PaperTradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmReset(BuildContext context, PortfolioProvider portfolio) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restart_alt_rounded, color: Color(0xFFFF3B3B)),
            const SizedBox(width: 8),
            Text(
              'Reset Paper Portfolio?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'This will reset your paper trading balance back to simulated ₹1,00,000 and clear all positions, limit orders, and trade history.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF8892A4))),
          ),
          ElevatedButton(
            onPressed: () {
              portfolio.resetPortfolio();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Paper portfolio reset to ₹1,00,000!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF0066CC),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B3B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Capital'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    // Listen to market ticks so floating P&L ticks in real-time
    context.watch<MarketTickerNotifier>();

    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final totalValue = portfolio.totalPortfolioValue;
        final virtualCash = portfolio.virtualCash;
        final totalInvested = portfolio.totalInvested;
        final floatingPnL = portfolio.getPnL();
        final floatingPnLPct = portfolio.getPnLPercent();
        final isProfit = floatingPnL >= 0;
        final spots = portfolio.getEquitySpots();

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
                    color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF0066CC),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Paper Trading 100% Pro',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF8892A4)),
                tooltip: 'Reset Portfolio',
                onPressed: () => _confirmReset(context, portfolio),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Top Balance Card with Equity Curve ─────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF0066CC), const Color(0xFF004499)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL PORTFOLIO VALUE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SIMULATED ₹1L',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormatter.format(totalValue),
                      style: GoogleFonts.robotoMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                          size: 20,
                        ),
                        Text(
                          '${isProfit ? "+" : ""}${currencyFormatter.format(floatingPnL)} (${isProfit ? "+" : ""}${floatingPnLPct.toStringAsFixed(2)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Unrealized P&L',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),

                    // ── Mini Equity Curve Sparkline ────────────────────────
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isProfit ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8))
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available Cash', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(virtualCash),
                                style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invested', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(totalInvested),
                                style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Win Rate', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text(
                                '${portfolio.winRate.toStringAsFixed(0)}%',
                                style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4ADE80)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tab Bar ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8892A4),
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Positions (${portfolio.positions.length})'),
                    Tab(text: 'Limit Orders (${portfolio.activeLimitOrders.length})'),
                    Tab(text: 'Ledger (${portfolio.tradeHistory.length})'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Tab Content ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Positions
                    portfolio.positions.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Active Positions',
                            subtitle: 'Explore 2000+ stocks and swipe to execute zero-risk paper trades.',
                            buttonText: 'Explore Stocks',
                            onTap: () => context.go('/search'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.positions.length,
                            itemBuilder: (context, idx) {
                              final entry = portfolio.positions.entries.elementAt(idx);
                              final pos = entry.value;
                              final stock = StockRepository.getStock(pos.ticker);
                              final currentPrice = stock.price;
                              final currentValue = currentPrice * pos.quantity;
                              final positionPnL = currentValue - pos.totalInvested;
                              final positionPnLPct = pos.totalInvested > 0
                                  ? (positionPnL / pos.totalInvested) * 100
                                  : 0.0;
                              final posProfit = positionPnL >= 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: InkWell(
                                  onTap: () => context.push('/stock/${pos.ticker}'),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        TickerLogo(
                                          ticker: stock.ticker,
                                          logoUrl: stock.logoUrl,
                                          logoColor: stock.logoColor,
                                          size: 36,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pos.ticker,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                '${pos.quantity} Shares • Avg ₹${pos.avgPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF8892A4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormatter.format(currentValue),
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '${posProfit ? "+" : ""}${currencyFormatter.format(positionPnL)} (${posProfit ? "+" : ""}${positionPnLPct.toStringAsFixed(2)}%)',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: posProfit ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 2: Limit Orders
                    portfolio.limitOrders.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Limit Orders',
                            subtitle: 'Place target price limit orders on any stock to execute automatically when triggered.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.limitOrders.length,
                            itemBuilder: (context, idx) {
                              final order = portfolio.limitOrders[idx];
                              final isBuy = order.isBuy;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBuy
                                              ? const Color(0xFF00C853).withValues(alpha: 0.12)
                                              : const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isBuy ? 'LIMIT BUY' : 'LIMIT SELL',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.ticker,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '${order.quantity} Shares @ Target ₹${order.limitPrice.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (order.isExecuted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'EXECUTED',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF00C853),
                                            ),
                                          ),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFFF3B3B)),
                                          tooltip: 'Cancel Order',
                                          onPressed: () {
                                            portfolio.cancelLimitOrder(order.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Limit order cancelled'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 3: Trade History Ledger
                    portfolio.tradeHistory.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Trade History Yet',
                            subtitle: 'Orders executed via SwipeToExecute will appear here with entry price and realized P&L.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.tradeHistory.length,
                            itemBuilder: (context, idx) {
                              final trade = portfolio.tradeHistory[idx];
                              final timeStr = DateFormat('dd MMM, hh:mm a').format(trade.timestamp);
                              final isBuy = trade.isBuy;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBuy
                                              ? const Color(0xFF00C853).withValues(alpha: 0.12)
                                              : const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isBuy ? 'BUY' : 'SELL',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trade.ticker,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '${trade.quantity} @ ₹${trade.price.toStringAsFixed(2)} • $timeStr',
                                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isBuy)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Realized P&L',
                                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8892A4)),
                                            ),
                                            Text(
                                              '${trade.realizedPnL >= 0 ? "+" : ""}${currencyFormatter.format(trade.realizedPnL)}',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: trade.realizedPnL >= 0
                                                    ? const Color(0xFF00C853)
                                                    : const Color(0xFFFF3B3B),
                                              ),
                                            ),
                                          ],
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 40,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8892A4),
                height: 1.5,
              ),
            ),
            if (buttonText != null && onTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
