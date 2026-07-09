import 'package:flutter_test/flutter_test.dart';
import 'package:phonerep_mobile/main.dart';

void main() {
  testWidgets('PhoneRep smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhoneRepApp());

    // Verify that the title is rendered.
    expect(find.text('PhoneRep Check'), findsOneWidget);
  });
}
