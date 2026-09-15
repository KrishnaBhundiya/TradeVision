import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MarketDepthWidget extends StatelessWidget {
  final double currentPrice;

  const MarketDepthWidget({
    super.key,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Generate 5-level Bids (Buyers) & Asks (Sellers) based on current price
    final bids = [
      {'price': currentPrice - 0.50, 'qty': 1420, 'orders': 18},
      {'price': currentPrice - 1.10, 'qty': 2850, 'orders': 34},
      {'price': currentPrice - 1.85, 'qty': 4100, 'orders': 52},
      {'price': currentPrice - 2.50, 'qty': 6900, 'orders': 89},
      {'price': currentPrice - 3.20, 'qty': 11450, 'orders': 140},
    ];

    final asks = [
      {'price': currentPrice + 0.55, 'qty': 980, 'orders': 14},
      {'price': currentPrice + 1.25, 'qty': 1840, 'orders': 22},
      {'price': currentPrice + 1.95, 'qty': 3200, 'orders': 41},
      {'price': currentPrice + 2.70, 'qty': 5400, 'orders': 78},
      {'price': currentPrice + 3.45, 'qty': 9800, 'orders': 112},
    ];

    const totalBidQty = 26720;
    const totalAskQty = 21220;
    const buyPercent = 55.7;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Buyers & Sellers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Buyer vs Seller Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buyers: 55.7% ($totalBidQty Qty)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gain,
                    ),
                  ),
                  Text(
                    'Sellers: 44.3% ($totalAskQty Qty)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.loss,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (buyPercent * 10).toInt(),
                        child: Container(color: AppColors.gain),
                      ),
                      Expanded(
                        flex: ((100 - buyPercent) * 10).toInt(),
                        child: Container(color: AppColors.loss),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Level 2 Table Header
          Row(
            children: [
              // Bids Side Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BUYERS PAYING (BID)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gain)),
                    Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              const VerticalDivider(width: 16),
              // Asks Side Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SELLERS ASKING (ASK)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.loss)),
                    Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 12, color: theme.dividerColor),

          // 5 Rows of Bids vs Asks
          Column(
            children: List.generate(5, (i) {
              final bid = bids[i];
              final ask = asks[i];
              final bidPrice = (bid['price'] as double).toStringAsFixed(2);
              final askPrice = (ask['price'] as double).toStringAsFixed(2);
              final bidQty = bid['qty'].toString();
              final askQty = ask['qty'].toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Bid Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹$bidPrice', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.gain)),
                          Text(bidQty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Ask Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹$askPrice', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.loss)),
                          Text(askQty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
