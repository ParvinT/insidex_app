import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:insidex_app/app.dart';
import 'package:insidex_app/providers/theme_provider.dart';
import 'package:insidex_app/providers/locale_provider.dart';

void main() {
  testWidgets('App launches and shows splash screen',
      (WidgetTester tester) async {
    final localeProvider = await LocaleProvider.initialize();
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: InsidexApp(localeProvider: localeProvider),
      ),
    );

    // Verify that splash screen is shown
    expect(find.text('Sound Healing & HypnoTracks'), findsOneWidget);
  });
}
