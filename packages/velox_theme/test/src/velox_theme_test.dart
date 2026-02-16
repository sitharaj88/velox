// ignore_for_file: cascade_invocations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velox_theme/velox_theme.dart';

void main() {
  group('VeloxThemeMode', () {
    test('toThemeMode converts correctly', () {
      expect(VeloxThemeMode.light.toThemeMode(), ThemeMode.light);
      expect(VeloxThemeMode.dark.toThemeMode(), ThemeMode.dark);
      expect(VeloxThemeMode.system.toThemeMode(), ThemeMode.system);
    });

    test('fromThemeMode converts correctly', () {
      expect(VeloxThemeMode.fromThemeMode(ThemeMode.light), VeloxThemeMode.light);
      expect(VeloxThemeMode.fromThemeMode(ThemeMode.dark), VeloxThemeMode.dark);
      expect(
        VeloxThemeMode.fromThemeMode(ThemeMode.system),
        VeloxThemeMode.system,
      );
    });
  });

  group('VeloxColorScheme', () {
    test('light factory creates valid scheme', () {
      final scheme = VeloxColorScheme.light();
      expect(scheme.success, isNotNull);
      expect(scheme.warning, isNotNull);
      expect(scheme.info, isNotNull);
    });

    test('dark factory creates valid scheme', () {
      final scheme = VeloxColorScheme.dark();
      expect(scheme.success, isNotNull);
      expect(scheme.warning, isNotNull);
      expect(scheme.info, isNotNull);
    });

    test('copyWith replaces fields', () {
      final scheme = VeloxColorScheme.light();
      final modified = scheme.copyWith(success: Colors.green);
      expect(modified.success, Colors.green);
      expect(modified.warning, scheme.warning);
    });

    test('lerp interpolates between schemes', () {
      final a = VeloxColorScheme.light();
      final b = VeloxColorScheme.dark();
      final result = VeloxColorScheme.lerp(a, b, 0.5);
      expect(result.success, isNotNull);
    });
  });

  group('VeloxColorSchemeExtension', () {
    test('copyWith replaces colors', () {
      final ext = VeloxColorSchemeExtension(
        veloxColors: VeloxColorScheme.light(),
      );
      final darkColors = VeloxColorScheme.dark();
      final copied = ext.copyWith(veloxColors: darkColors);
      expect(copied.veloxColors.success, darkColors.success);
    });

    test('lerp interpolates extensions', () {
      final a = VeloxColorSchemeExtension(
        veloxColors: VeloxColorScheme.light(),
      );
      final b = VeloxColorSchemeExtension(
        veloxColors: VeloxColorScheme.dark(),
      );
      final result = a.lerp(b, 0.5);
      expect(result, isA<VeloxColorSchemeExtension>());
    });

    test('lerp returns self when other is null', () {
      final a = VeloxColorSchemeExtension(
        veloxColors: VeloxColorScheme.light(),
      );
      final result = a.lerp(null, 0.5);
      expect(result, same(a));
    });
  });

  group('VeloxTextTheme', () {
    test('creates with defaults', () {
      const textTheme = VeloxTextTheme();
      expect(textTheme.fontFamily, isNull);
      expect(textTheme.scaleFactor, 1.0);
      expect(textTheme.letterSpacingFactor, 1.0);
    });

    test('toTextTheme generates a TextTheme', () {
      const textTheme = VeloxTextTheme(fontFamily: 'Roboto');
      final result = textTheme.toTextTheme();
      expect(result, isA<TextTheme>());
    });

    test('copyWith replaces fields', () {
      const textTheme = VeloxTextTheme();
      final modified = textTheme.copyWith(fontFamily: 'Inter', scaleFactor: 1.2);
      expect(modified.fontFamily, 'Inter');
      expect(modified.scaleFactor, 1.2);
      expect(modified.letterSpacingFactor, 1.0);
    });
  });

  group('VeloxThemeConfig', () {
    test('creates with required fields', () {
      const config = VeloxThemeConfig(seedColor: Colors.blue);
      expect(config.seedColor, Colors.blue);
      expect(config.useMaterial3, isTrue);
      expect(config.borderRadius, 12.0);
      expect(config.elevation, 1.0);
    });

    test('effectiveTextTheme respects fontFamily override', () {
      const config = VeloxThemeConfig(
        seedColor: Colors.blue,
        fontFamily: 'Poppins',
      );
      expect(config.effectiveTextTheme.fontFamily, 'Poppins');
    });

    test('effectiveTextTheme uses textTheme when no fontFamily', () {
      const config = VeloxThemeConfig(
        seedColor: Colors.blue,
        textTheme: VeloxTextTheme(fontFamily: 'Inter'),
      );
      expect(config.effectiveTextTheme.fontFamily, 'Inter');
    });

    test('copyWith replaces fields', () {
      const config = VeloxThemeConfig(seedColor: Colors.blue);
      final modified = config.copyWith(
        seedColor: Colors.red,
        borderRadius: 16,
      );
      expect(modified.seedColor, Colors.red);
      expect(modified.borderRadius, 16.0);
      expect(modified.useMaterial3, isTrue);
    });
  });

  group('VeloxThemeData', () {
    const config = VeloxThemeConfig(seedColor: Colors.blue);

    test('light generates a valid light theme', () {
      final theme = VeloxThemeData.light(config);
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(
        theme.extension<VeloxColorSchemeExtension>(),
        isNotNull,
      );
    });

    test('dark generates a valid dark theme', () {
      final theme = VeloxThemeData.dark(config);
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(
        theme.extension<VeloxColorSchemeExtension>(),
        isNotNull,
      );
    });

    test('light theme includes custom colors', () {
      final customColors = VeloxColorScheme.light().copyWith(
        success: Colors.teal,
      );
      final customConfig = config.copyWith(lightColors: customColors);
      final theme = VeloxThemeData.light(customConfig);
      final ext = theme.extension<VeloxColorSchemeExtension>();
      expect(ext!.veloxColors.success, Colors.teal);
    });

    test('dark theme includes custom colors', () {
      final customColors = VeloxColorScheme.dark().copyWith(
        warning: Colors.amber,
      );
      final customConfig = config.copyWith(darkColors: customColors);
      final theme = VeloxThemeData.dark(customConfig);
      final ext = theme.extension<VeloxColorSchemeExtension>();
      expect(ext!.veloxColors.warning, Colors.amber);
    });

    test('applies border radius to card theme', () {
      const customConfig = VeloxThemeConfig(
        seedColor: Colors.blue,
        borderRadius: 20,
      );
      final theme = VeloxThemeData.light(customConfig);
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      final radius =
          cardShape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, 20.0);
    });
  });

  group('VeloxThemeBuilder', () {
    testWidgets('builds with light and dark themes', (tester) async {
      late ThemeData capturedLight;
      late ThemeData capturedDark;
      late VeloxThemeMode capturedMode;

      await tester.pumpWidget(
        VeloxThemeBuilder(
          config: const VeloxThemeConfig(seedColor: Colors.blue),
          builder: (context, light, dark, mode) {
            capturedLight = light;
            capturedDark = dark;
            capturedMode = mode;
            return MaterialApp(
              theme: light,
              darkTheme: dark,
              themeMode: mode.toThemeMode(),
              home: const SizedBox(),
            );
          },
        ),
      );

      expect(capturedLight.brightness, Brightness.light);
      expect(capturedDark.brightness, Brightness.dark);
      expect(capturedMode, VeloxThemeMode.system);
    });

    testWidgets('setMode updates the theme mode', (tester) async {
      VeloxThemeMode? lastMode;

      await tester.pumpWidget(
        VeloxThemeBuilder(
          config: const VeloxThemeConfig(seedColor: Colors.blue),
          builder: (context, light, dark, mode) {
            lastMode = mode;
            return MaterialApp(
              theme: light,
              darkTheme: dark,
              themeMode: mode.toThemeMode(),
              home: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () =>
                      VeloxThemeBuilder.of(ctx).setMode(VeloxThemeMode.dark),
                  child: const Text('Toggle'),
                ),
              ),
            );
          },
        ),
      );

      expect(lastMode, VeloxThemeMode.system);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(lastMode, VeloxThemeMode.dark);
    });

    testWidgets('toggleMode cycles modes', (tester) async {
      VeloxThemeMode? lastMode;

      await tester.pumpWidget(
        VeloxThemeBuilder(
          config: const VeloxThemeConfig(seedColor: Colors.blue),
          initialMode: VeloxThemeMode.light,
          builder: (context, light, dark, mode) {
            lastMode = mode;
            return MaterialApp(
              theme: light,
              darkTheme: dark,
              themeMode: mode.toThemeMode(),
              home: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => VeloxThemeBuilder.of(ctx).toggleMode(),
                  child: const Text('Toggle'),
                ),
              ),
            );
          },
        ),
      );

      expect(lastMode, VeloxThemeMode.light);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(lastMode, VeloxThemeMode.dark);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(lastMode, VeloxThemeMode.light);
    });

    testWidgets('maybeOf returns null when no builder exists', (tester) async {
      VeloxThemeBuilderState? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              result = VeloxThemeBuilder.maybeOf(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNull);
    });
  });

  group('VeloxThemeContext', () {
    testWidgets('provides theme accessors', (tester) async {
      late ThemeData theme;
      late ColorScheme colorScheme;
      late TextTheme textTheme;
      late bool isDark;
      VeloxColorScheme? veloxColors;

      await tester.pumpWidget(
        VeloxThemeBuilder(
          config: const VeloxThemeConfig(seedColor: Colors.blue),
          builder: (context, light, dark, mode) => MaterialApp(
            theme: light,
            darkTheme: dark,
            themeMode: mode.toThemeMode(),
            home: Builder(
              builder: (ctx) {
                theme = ctx.veloxTheme;
                colorScheme = ctx.veloxColorScheme;
                textTheme = ctx.veloxTextTheme;
                isDark = ctx.isDarkMode;
                veloxColors = ctx.veloxColors;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(theme, isNotNull);
      expect(colorScheme, isNotNull);
      expect(textTheme, isNotNull);
      expect(isDark, isFalse);
      expect(veloxColors, isNotNull);
    });
  });
}
