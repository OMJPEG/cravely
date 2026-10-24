import 'package:cravely/main.dart';
import 'package:cravely/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('CravelyApp loads splash screen smoke test', (WidgetTester tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const CravelyApp(),
      ),
    );

    // Verify splash screen displays the app name and tagline
    expect(find.text(appName), findsOneWidget);
    expect(find.text(appTagline), findsOneWidget);
  });
}
