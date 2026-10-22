import 'package:flutter_test/flutter_test.dart';
import 'package:ds1cpsmartmeet/app/app.dart';

void main() {
  testWidgets('SmartMeet app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartMeetApp());

    expect(find.byType(SmartMeetApp), findsOneWidget);
  });
}
