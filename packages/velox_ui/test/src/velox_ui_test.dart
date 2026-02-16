import 'package:flutter_test/flutter_test.dart';
import 'package:velox_ui/velox_ui.dart';

void main() {
  test('velox_ui re-exports velox_theme types', () {
    // Verify key types from each package are accessible
    expect(VeloxThemeMode.values, isNotEmpty);
  });

  test('velox_ui re-exports velox_responsive types', () {
    expect(VeloxBreakpoint.values, isNotEmpty);
  });

  test('velox_ui re-exports velox_buttons types', () {
    expect(VeloxButtonSize.values, isNotEmpty);
    expect(VeloxButtonVariant.values, isNotEmpty);
  });

  test('velox_ui re-exports velox_animations types', () {
    expect(VeloxSwitchTransition.values, isNotEmpty);
  });

  test('velox_ui re-exports velox_forms types', () {
    expect(VeloxValidators.required, isNotNull);
  });}
