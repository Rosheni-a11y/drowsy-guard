import 'package:flutter_test/flutter_test.dart';
import 'package:drowsy_guard/main.dart';

void main() {
  testWidgets('App should start', (WidgetTester tester) async {
    await tester.pumpWidget(const DrowsyGuardApp());
    expect(find.text('Drowsy Guard'), findsOneWidget);
  });
}
