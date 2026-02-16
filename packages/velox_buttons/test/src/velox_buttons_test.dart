// ignore_for_file: cascade_invocations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velox_buttons/velox_buttons.dart';

void main() {
  Widget buildApp({required Widget child}) => MaterialApp(
        home: Scaffold(body: child),
      );

  group('VeloxButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Click Me',
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildApp(
          child: VeloxButton(
            label: 'Tap',
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('disabled state does not trigger onPressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildApp(
          child: VeloxButton(
            label: 'Disabled',
            onPressed: () => tapped = true,
            isEnabled: false,
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      expect(tapped, isFalse);
    });

    testWidgets('renders filled variant', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Filled',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders outlined variant', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Outlined',
            variant: VeloxButtonVariant.outlined,
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders text variant', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Text',
            variant: VeloxButtonVariant.text,
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders tonal variant', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Tonal',
            variant: VeloxButtonVariant.tonal,
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Tonal'), findsOneWidget);
    });

    testWidgets('renders small size', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Small',
            size: VeloxButtonSize.small,
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('renders medium size', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Medium',
          ),
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders large size', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Large',
            size: VeloxButtonSize.large,
          ),
        ),
      );

      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'With Icon',
            icon: Icons.add,
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButton(
            label: 'Colored',
            color: Colors.red,
          ),
        ),
      );

      expect(find.text('Colored'), findsOneWidget);
    });
  });

  group('VeloxLoadingButton', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxLoadingButton(
            label: 'Submit',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables button when loading', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildApp(
          child: VeloxLoadingButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(tapped, isFalse);
    });

    testWidgets('shows label when not loading', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: VeloxLoadingButton(
            label: 'Submit',
            isLoading: false,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('VeloxGradientButton', () {
    testWidgets('renders with gradient', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxGradientButton(
            label: 'Gradient',
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
          ),
        ),
      );

      expect(find.text('Gradient'), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildApp(
          child: VeloxGradientButton(
            label: 'Tap Gradient',
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Gradient'));
      expect(tapped, isTrue);
    });
  });

  group('VeloxIconButton', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxIconButton(
            icon: Icons.star,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows badge when showBadge is true', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxIconButton(
            icon: Icons.notifications,
            showBadge: true,
            badgeLabel: '5',
          ),
        ),
      );

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does not show badge when showBadge is false', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxIconButton(
            icon: Icons.star,
          ),
        ),
      );

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('shows tooltip', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxIconButton(
            icon: Icons.star,
            tooltip: 'Favorite',
          ),
        ),
      );

      expect(find.byTooltip('Favorite'), findsOneWidget);
    });
  });

  group('VeloxButtonGroup', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButtonGroup(
            children: [
              VeloxButton(label: 'One'),
              VeloxButton(label: 'Two'),
              VeloxButton(label: 'Three'),
            ],
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('uses Wrap with correct direction', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButtonGroup(
            direction: Axis.vertical,
            children: [
              VeloxButton(label: 'A'),
              VeloxButton(label: 'B'),
            ],
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.direction, Axis.vertical);
    });

    testWidgets('applies custom spacing', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const VeloxButtonGroup(
            spacing: 16,
            children: [
              VeloxButton(label: 'X'),
              VeloxButton(label: 'Y'),
            ],
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, 16);
    });
  });

  group('VeloxButtonSize', () {
    test('height values are correct', () {
      expect(VeloxButtonSize.small.height, 32);
      expect(VeloxButtonSize.medium.height, 40);
      expect(VeloxButtonSize.large.height, 48);
    });

    test('padding values are not null', () {
      expect(VeloxButtonSize.small.padding, isNotNull);
      expect(VeloxButtonSize.medium.padding, isNotNull);
      expect(VeloxButtonSize.large.padding, isNotNull);
    });
  });
}
