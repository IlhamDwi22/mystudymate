import 'package:flutter_test/flutter_test.dart';
import 'package:mystudymate_app/main.dart';

void main() {
  testWidgets('MyStudyMate smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app displays "MyStudyMate".
    expect(find.text('MyStudyMate'), findsOneWidget);
  });
}
