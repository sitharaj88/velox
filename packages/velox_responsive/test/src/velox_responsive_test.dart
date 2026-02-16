// ignore_for_file: cascade_invocations

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velox_responsive/velox_responsive.dart';

void main() {
  group('VeloxBreakpoint', () {
    group('fromWidth', () {
      test('returns mobile for width 0', () {
        expect(VeloxBreakpoint.fromWidth(0), VeloxBreakpoint.mobile);
      });

      test('returns mobile for width 599', () {
        expect(VeloxBreakpoint.fromWidth(599), VeloxBreakpoint.mobile);
      });

      test('returns tablet for width 600', () {
        expect(VeloxBreakpoint.fromWidth(600), VeloxBreakpoint.tablet);
      });

      test('returns tablet for width 1023', () {
        expect(VeloxBreakpoint.fromWidth(1023), VeloxBreakpoint.tablet);
      });

      test('returns desktop for width 1024', () {
        expect(VeloxBreakpoint.fromWidth(1024), VeloxBreakpoint.desktop);
      });

      test('returns desktop for width 1439', () {
        expect(VeloxBreakpoint.fromWidth(1439), VeloxBreakpoint.desktop);
      });

      test('returns wide for width 1440', () {
        expect(VeloxBreakpoint.fromWidth(1440), VeloxBreakpoint.wide);
      });

      test('returns wide for width 2000', () {
        expect(VeloxBreakpoint.fromWidth(2000), VeloxBreakpoint.wide);
      });

      test('returns mobile for negative width', () {
        expect(VeloxBreakpoint.fromWidth(-1), VeloxBreakpoint.mobile);
      });
    });

    group('minWidth', () {
      test('mobile starts at 0', () {
        expect(VeloxBreakpoint.mobile.minWidth, 0);
      });

      test('tablet starts at 600', () {
        expect(VeloxBreakpoint.tablet.minWidth, 600);
      });

      test('desktop starts at 1024', () {
        expect(VeloxBreakpoint.desktop.minWidth, 1024);
      });

      test('wide starts at 1440', () {
        expect(VeloxBreakpoint.wide.minWidth, 1440);
      });
    });

    group('maxWidth', () {
      test('mobile ends at 599', () {
        expect(VeloxBreakpoint.mobile.maxWidth, 599);
      });

      test('tablet ends at 1023', () {
        expect(VeloxBreakpoint.tablet.maxWidth, 1023);
      });

      test('desktop ends at 1439', () {
        expect(VeloxBreakpoint.desktop.maxWidth, 1439);
      });

      test('wide has infinite maxWidth', () {
        expect(VeloxBreakpoint.wide.maxWidth, double.infinity);
      });
    });
  });

  group('VeloxResponsiveValue', () {
    test('resolves mobile value for mobile breakpoint', () {
      const value = VeloxResponsiveValue<int>(mobile: 1, tablet: 2);
      expect(value.resolve(VeloxBreakpoint.mobile), 1);
    });

    test('resolves tablet value for tablet breakpoint', () {
      const value = VeloxResponsiveValue<int>(mobile: 1, tablet: 2);
      expect(value.resolve(VeloxBreakpoint.tablet), 2);
    });

    test('falls back to mobile when tablet is null', () {
      const value = VeloxResponsiveValue<int>(mobile: 1);
      expect(value.resolve(VeloxBreakpoint.tablet), 1);
    });

    test('falls back to tablet when desktop is null', () {
      const value = VeloxResponsiveValue<int>(mobile: 1, tablet: 2);
      expect(value.resolve(VeloxBreakpoint.desktop), 2);
    });

    test('falls back to mobile when tablet and desktop are null', () {
      const value = VeloxResponsiveValue<int>(mobile: 1);
      expect(value.resolve(VeloxBreakpoint.desktop), 1);
    });

    test('falls back to desktop when wide is null', () {
      const value = VeloxResponsiveValue<int>(
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );
      expect(value.resolve(VeloxBreakpoint.wide), 3);
    });

    test('falls back to mobile when all others are null for wide', () {
      const value = VeloxResponsiveValue<int>(mobile: 1);
      expect(value.resolve(VeloxBreakpoint.wide), 1);
    });

    test('resolves all explicit values correctly', () {
      const value = VeloxResponsiveValue<int>(
        mobile: 1,
        tablet: 2,
        desktop: 3,
        wide: 4,
      );
      expect(value.resolve(VeloxBreakpoint.mobile), 1);
      expect(value.resolve(VeloxBreakpoint.tablet), 2);
      expect(value.resolve(VeloxBreakpoint.desktop), 3);
      expect(value.resolve(VeloxBreakpoint.wide), 4);
    });
  });

  group('VeloxResponsiveBuilder', () {
    testWidgets('renders with mobile breakpoint for narrow width', (
      tester,
    ) async {
      VeloxBreakpoint? capturedBreakpoint;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: VeloxResponsiveBuilder(
              builder: (context, breakpoint, constraints) {
                capturedBreakpoint = breakpoint;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedBreakpoint, VeloxBreakpoint.mobile);
    });

    testWidgets('renders with tablet breakpoint for medium width', (
      tester,
    ) async {
      VeloxBreakpoint? capturedBreakpoint;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 700,
            height: 400,
            child: VeloxResponsiveBuilder(
              builder: (context, breakpoint, constraints) {
                capturedBreakpoint = breakpoint;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedBreakpoint, VeloxBreakpoint.tablet);
    });

    testWidgets('renders with desktop breakpoint for wide width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      VeloxBreakpoint? capturedBreakpoint;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 1200,
            height: 400,
            child: VeloxResponsiveBuilder(
              builder: (context, breakpoint, constraints) {
                capturedBreakpoint = breakpoint;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedBreakpoint, VeloxBreakpoint.desktop);
    });

    testWidgets('passes constraints to builder', (tester) async {
      BoxConstraints? capturedConstraints;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 500,
            height: 400,
            child: VeloxResponsiveBuilder(
              builder: (context, breakpoint, constraints) {
                capturedConstraints = constraints;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(capturedConstraints, isNotNull);
      expect(capturedConstraints!.maxWidth, 500);
    });
  });

  group('VeloxResponsiveGrid', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: VeloxResponsiveGrid(
                columns: VeloxResponsiveValue<int>(mobile: 2),
                children: [
                  VeloxGridItem(child: Text('A')),
                  VeloxGridItem(child: Text('B')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('uses Wrap internally', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: VeloxResponsiveGrid(
                columns: VeloxResponsiveValue<int>(mobile: 2),
                spacing: 8,
                runSpacing: 12,
                children: [
                  VeloxGridItem(child: Text('A')),
                ],
              ),
            ),
          ),
        ),
      );

      final wrapFinder = find.byType(Wrap);
      expect(wrapFinder, findsOneWidget);

      final wrap = tester.widget<Wrap>(wrapFinder);
      expect(wrap.spacing, 8);
      expect(wrap.runSpacing, 12);
    });
  });

  group('VeloxResponsivePadding', () {
    testWidgets('applies mobile padding for narrow width', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: VeloxResponsivePadding(
                padding: VeloxResponsiveValue<EdgeInsets>(
                  mobile: EdgeInsets.all(8),
                  tablet: EdgeInsets.all(16),
                ),
                child: Text('Hello'),
              ),
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);

      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.all(8));
    });

    testWidgets('applies tablet padding for medium width', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 700,
              height: 400,
              child: VeloxResponsivePadding(
                padding: VeloxResponsiveValue<EdgeInsets>(
                  mobile: EdgeInsets.all(8),
                  tablet: EdgeInsets.all(16),
                ),
                child: Text('Hello'),
              ),
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);

      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: VeloxResponsivePadding(
                padding: VeloxResponsiveValue<EdgeInsets>(
                  mobile: EdgeInsets.all(8),
                ),
                child: Text('Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('VeloxScreenInfo', () {
    Widget buildTestApp({
      required Size size,
      required Widget child,
    }) =>
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child,
          ),
        );

    testWidgets('screenWidth returns correct value', (tester) async {
      double? width;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(400, 800),
          child: Builder(
            builder: (context) {
              width = context.screenWidth;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(width, 400);
    });

    testWidgets('screenHeight returns correct value', (tester) async {
      double? height;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(400, 800),
          child: Builder(
            builder: (context) {
              height = context.screenHeight;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(height, 800);
    });

    testWidgets('isMobile returns true for mobile width', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(400, 800),
          child: Builder(
            builder: (context) {
              result = context.isMobile;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isTablet returns true for tablet width', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(700, 800),
          child: Builder(
            builder: (context) {
              result = context.isTablet;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isDesktop returns true for desktop width', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1200, 800),
          child: Builder(
            builder: (context) {
              result = context.isDesktop;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('isWide returns true for wide width', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1500, 800),
          child: Builder(
            builder: (context) {
              result = context.isWide;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('breakpoint returns correct value', (tester) async {
      VeloxBreakpoint? result;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1024, 800),
          child: Builder(
            builder: (context) {
              result = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, VeloxBreakpoint.desktop);
    });
  });
}
