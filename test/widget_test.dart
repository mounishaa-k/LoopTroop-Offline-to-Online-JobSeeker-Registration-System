import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App smoke test — splash screen renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FairTrackApp());
    // Just verify the app builds without crashing
    expect(find.byType(FairTrackApp), findsOneWidget);
  });
}
