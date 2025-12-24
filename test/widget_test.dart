import 'package:flutter_test/flutter_test.dart';
import 'package:blockpay/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BlockPayApp());

    // Verify that we start with the Splash Screen (or at least the app builds)
    expect(find.byType(BlockPayApp), findsOneWidget);
  });
}
