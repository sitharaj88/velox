// ignore_for_file: cascade_invocations

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velox_animations/velox_animations.dart';

void main() {
  group('VeloxFadeIn', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeIn(
            child: Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('starts with zero opacity and animates to full', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeIn(
            child: Text('Fade'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxFadeIn),
        matching: find.byType(FadeTransition),
      );
      var fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 0.0);

      await tester.pumpAndSettle();

      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);
    });

    testWidgets('respects delay before animating', (tester) async {
      const delay = Duration(milliseconds: 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeIn(
            delay: delay,
            child: Text('Delayed'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxFadeIn),
        matching: find.byType(FadeTransition),
      );
      var fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 0.0);

      // Pump past the delay
      await tester.pump(delay);
      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 0.0);

      // Settle the animation
      await tester.pumpAndSettle();
      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);
    });

    testWidgets('uses custom duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeIn(
            duration: Duration(milliseconds: 600),
            child: Text('Custom'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      final finder = find.descendant(
        of: find.byType(VeloxFadeIn),
        matching: find.byType(FadeTransition),
      );
      var fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, greaterThan(0.0));
      expect(fadeTransition.opacity.value, lessThan(1.0));

      await tester.pumpAndSettle();
      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);
    });
  });

  group('VeloxFadeOut', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeOut(
            child: Text('Goodbye'),
          ),
        ),
      );

      expect(find.text('Goodbye'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('starts visible and fades out', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeOut(
            child: Text('FadeOut'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxFadeOut),
        matching: find.byType(FadeTransition),
      );
      var fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);

      await tester.pumpAndSettle();

      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 0.0);
    });

    testWidgets('respects delay', (tester) async {
      const delay = Duration(milliseconds: 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxFadeOut(
            delay: delay,
            child: Text('Delayed Out'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxFadeOut),
        matching: find.byType(FadeTransition),
      );
      var fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);

      await tester.pump(delay);
      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 1.0);

      await tester.pumpAndSettle();
      fadeTransition = tester.widget<FadeTransition>(finder);
      expect(fadeTransition.opacity.value, 0.0);
    });
  });

  group('VeloxSlideIn', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxSlideIn(
            child: Text('Slide'),
          ),
        ),
      );

      expect(find.text('Slide'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('slides in from all directions', (tester) async {
      for (final direction in VeloxSlideDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: VeloxSlideIn(
              direction: direction,
              child: const Text('Dir'),
            ),
          ),
        );

        expect(find.text('Dir'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(VeloxSlideIn),
            matching: find.byType(SlideTransition),
          ),
          findsOneWidget,
        );

        await tester.pumpAndSettle();
      }
    });

    testWidgets('animates to final position', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxSlideIn(
            child: Text('SlideAnim'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final finder = find.descendant(
        of: find.byType(VeloxSlideIn),
        matching: find.byType(SlideTransition),
      );
      final slideTransition = tester.widget<SlideTransition>(finder);
      expect(slideTransition.position.value, Offset.zero);
    });

    testWidgets('respects delay before sliding', (tester) async {
      const delay = Duration(milliseconds: 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxSlideIn(
            delay: delay,
            direction: VeloxSlideDirection.right,
            child: Text('SlideDelay'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxSlideIn),
        matching: find.byType(SlideTransition),
      );
      var slideTransition = tester.widget<SlideTransition>(finder);
      expect(slideTransition.position.value, const Offset(1, 0));

      await tester.pump(delay);
      await tester.pumpAndSettle();

      slideTransition = tester.widget<SlideTransition>(finder);
      expect(slideTransition.position.value, Offset.zero);
    });
  });

  group('VeloxScaleIn', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxScaleIn(
            child: Text('Scale'),
          ),
        ),
      );

      expect(find.text('Scale'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('animates from beginScale to full scale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxScaleIn(
            beginScale: 0.5,
            child: Text('ScaleAnim'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxScaleIn),
        matching: find.byType(ScaleTransition),
      );
      var scaleTransition = tester.widget<ScaleTransition>(finder);
      expect(scaleTransition.scale.value, 0.5);

      await tester.pumpAndSettle();

      scaleTransition = tester.widget<ScaleTransition>(finder);
      expect(scaleTransition.scale.value, 1.0);
    });

    testWidgets('respects delay before scaling', (tester) async {
      const delay = Duration(milliseconds: 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxScaleIn(
            delay: delay,
            child: Text('ScaleDelay'),
          ),
        ),
      );

      final finder = find.descendant(
        of: find.byType(VeloxScaleIn),
        matching: find.byType(ScaleTransition),
      );
      var scaleTransition = tester.widget<ScaleTransition>(finder);
      expect(scaleTransition.scale.value, 0.0);

      await tester.pump(delay);
      await tester.pumpAndSettle();

      scaleTransition = tester.widget<ScaleTransition>(finder);
      expect(scaleTransition.scale.value, 1.0);
    });
  });

  group('VeloxShimmer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxShimmer(
            child: SizedBox(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);

      // Shimmer repeats, so pump a few frames rather than settling
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('uses custom colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxShimmer(
            baseColor: Colors.blue,
            highlightColor: Colors.white,
            child: SizedBox(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('finds VeloxShimmer in the widget tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxShimmer(
            child: Text('Loading...'),
          ),
        ),
      );

      expect(find.byType(VeloxShimmer), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('VeloxStaggeredList', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxStaggeredList(
            children: [
              Text('Item 1'),
              Text('Item 2'),
              Text('Item 3'),
            ],
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);

      // Pump past all stagger delays and animations
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('wraps children in VeloxFadeIn and VeloxSlideIn', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxStaggeredList(
            children: [
              Text('A'),
              Text('B'),
            ],
          ),
        ),
      );

      expect(find.byType(VeloxFadeIn), findsNWidgets(2));
      expect(find.byType(VeloxSlideIn), findsNWidgets(2));

      // Pump past all stagger delays and animations
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });
  });

  group('VeloxAnimatedSwitcher', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            child: Text('Switch', key: ValueKey('a')),
          ),
        ),
      );

      expect(find.text('Switch'), findsOneWidget);
    });

    testWidgets('transitions between widgets with fade', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            child: Text('First', key: ValueKey('first')),
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            child: Text('Second', key: ValueKey('second')),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Second'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('supports scale transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            transition: VeloxSwitchTransition.scale,
            child: Text('Scale', key: ValueKey('s1')),
          ),
        ),
      );

      expect(find.text('Scale'), findsOneWidget);
    });

    testWidgets('supports slideUp transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            transition: VeloxSwitchTransition.slideUp,
            child: Text('Up', key: ValueKey('u1')),
          ),
        ),
      );

      expect(find.text('Up'), findsOneWidget);
    });

    testWidgets('supports slideDown transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VeloxAnimatedSwitcher(
            transition: VeloxSwitchTransition.slideDown,
            child: Text('Down', key: ValueKey('d1')),
          ),
        ),
      );

      expect(find.text('Down'), findsOneWidget);
    });
  });
}
