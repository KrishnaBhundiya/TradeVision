import 'package:flutter/material.dart';

class TickerLogo extends StatelessWidget {
  final String ticker;
  final String logoUrl;
  final Color logoColor;
  final double size;

  const TickerLogo({
    super.key,
    required this.ticker,
    this.logoUrl = '',
    this.logoColor = const Color(0xFF0066CC),
    this.size = 40.0,
  });

  String get _initials {
    final clean = ticker.replaceAll('.NS', '').replaceAll('.BO', '');
    if (clean.length <= 3) return clean;
    return clean.substring(0, 3);
  }

  /// Extract main website domain from stock logoUrl or websiteUrl
  String get _domain {
    if (logoUrl.contains('clearbit.com/')) {
      return logoUrl.split('clearbit.com/').last;
    }
    if (logoUrl.contains('favicons?domain=')) {
      return logoUrl.split('favicons?domain=').last.split('&').first;
    }
    return logoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.35;
    // Primary URL: Google High-Res 128px Official Favicon Service from Stock Website
    final primaryLogoUrl = _domain.contains('http')
        ? _domain
        : 'https://www.google.com/s2/favicons?domain=$_domain&sz=128';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: logoColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: logoColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Image.network(
          primaryLogoUrl,
          width: size * 0.75,
          height: size * 0.75,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Secondary Fallback: Clearbit Direct Official Brand Logo
            final secondaryLogoUrl = 'https://logo.clearbit.com/$_domain';
            return Image.network(
              secondaryLogoUrl,
              width: size * 0.75,
              height: size * 0.75,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildInitialsFallback(fontSize),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsFallback(fontSize);
          },
        ),
      ),
    );
  }

  Widget _buildInitialsFallback(double fontSize) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: logoColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
