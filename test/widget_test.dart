import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akalt/main.dart';

void main() {
  testWidgets('App starts with Splash Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AkaltApp()));

    // Verify that the Splash Screen is shown.
    expect(find.text('AKALT'), findsOneWidget);

    // Wait for the splash screen timer to finish and navigation to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
