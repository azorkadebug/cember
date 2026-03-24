import 'package:flutter_test/flutter_test.dart';

import 'package:cember/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CemberApp());
    expect(find.text('ÇEMBER'), findsOneWidget);
  });
}
