
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_multitracks/main.dart';

void main() {
  testWidgets('App Multitracks inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppMultitracks(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppMultitracks), findsOneWidget);
  });
}
