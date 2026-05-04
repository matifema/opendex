import 'package:flutter_test/flutter_test.dart';
import 'package:opendex/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PokeSnapApp());
    await tester.pumpAndSettle();

    expect(find.text('OpénDex'), findsOneWidget);
  });
}
