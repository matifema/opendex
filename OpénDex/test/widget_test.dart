import 'package:flutter_test/flutter_test.dart';
import 'package:pokegen_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PokeSnapApp());
    await tester.pumpAndSettle();

    // Verify that the app title is present (part of MaterialApp)
    // Note: 'PokéSnap PixelMon' is the title in MaterialApp, but it might not be rendered as text on screen directly unless in an AppBar.
    // The HomePage has an AppBar with 'Pet Battler'.
    expect(find.text('Pet Battler'), findsOneWidget);
  });
}
