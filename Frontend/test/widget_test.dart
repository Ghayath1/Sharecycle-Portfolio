import 'package:flutter_test/flutter_test.dart';
import 'package:sharecycleapp/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build the ShareCycleApp widget and trigger a frame.
    await tester.pumpWidget(const ShareCycleApp());

    // Check if the login screen title is present
    expect(find.text('Share Cycle'), findsOneWidget);
  });
}
