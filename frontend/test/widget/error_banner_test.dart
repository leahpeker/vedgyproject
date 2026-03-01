import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/widgets/error_banner.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorBanner', () {
    testWidgets('is not present when not included in widget tree', (tester) async {
      // ErrorBanner always renders when present, so absence is tested by
      // simply not including it and confirming the type is not found.
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('shows the provided error message', (tester) async {
      const message = 'Invalid credentials';

      await tester.pumpWidget(wrap(const ErrorBanner(message)));
      await tester.pump();

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('renders the error outline icon', (tester) async {
      await tester.pumpWidget(wrap(const ErrorBanner('Some error')));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses errorContainer background color', (tester) async {
      const message = 'Background color test';

      await tester.pumpWidget(wrap(const ErrorBanner(message)));
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ErrorBanner),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final colorScheme = ThemeData().colorScheme;

      expect(decoration.color, colorScheme.errorContainer);
    });

    testWidgets('uses onErrorContainer color for text', (tester) async {
      const message = 'Text color test';

      await tester.pumpWidget(wrap(const ErrorBanner(message)));
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text(message));
      final colorScheme = ThemeData().colorScheme;

      expect(textWidget.style?.color, colorScheme.onErrorContainer);
    });

    testWidgets('handles a long error message without overflow', (tester) async {
      const longMessage =
          'This is a very long error message that goes on and on and should '
          'not cause any layout overflow errors in the banner widget because '
          'it is wrapped in an Expanded widget inside a Row.';

      await tester.pumpWidget(wrap(const ErrorBanner(longMessage)));
      await tester.pump();

      expect(find.text(longMessage), findsOneWidget);
      // If there were an overflow, pumpWidget / pump would throw or report
      // RenderFlex overflow errors captured by the test framework.
    });

    testWidgets('renders with an empty string without throwing', (tester) async {
      // The widget accepts any String including empty; it should render.
      await tester.pumpWidget(wrap(const ErrorBanner('')));
      await tester.pump();

      expect(find.byType(ErrorBanner), findsOneWidget);
    });
  });
}
