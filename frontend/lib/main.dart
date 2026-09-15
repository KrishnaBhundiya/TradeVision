import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'core/theme/app_theme.dart';
import 'core/providers/portfolio_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/market_ticker_provider.dart';
import 'core/providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'widgets/connectivity_banner.dart';

import 'core/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handler FIRST — before everything
  AppErrorHandler.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Wrap entire startup in try-catch
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('StorageService init failed: $e');
    // Continue anyway — app can run without persisted prefs
  }

  final isLoggedIn = StorageService.getIsLoggedIn();
  final savedTheme = StorageService.getThemeMode();
  final initialTheme = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

  runApp(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWith((ref) => isLoggedIn),
        themeProvider.overrideWith((ref) => ThemeNotifier(initialTheme)),
      ],
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => PortfolioProvider()),
          provider.ChangeNotifierProvider(create: (_) => MarketTickerNotifier()),
        ],
        child: const TradeVisionApp(),
      ),
    ),
  );
}

class TradeVisionApp extends ConsumerWidget {
  const TradeVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return ConnectivityWrapper(
      child: MaterialApp.router(
        title: 'TradeVision',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
