import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('TradeVision app loads with entry flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TradeVisionApp(),
      ),
    );
    await tester.pump();
    expect(find.text('TradeVision'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
