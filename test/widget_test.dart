import 'package:flutter_test/flutter_test.dart';

import 'package:moonfin/app.dart';

void main() {
  testWidgets('App renders startup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MoonfinApp());
    expect(find.text('Moonfin'), findsOneWidget);
  });
}
