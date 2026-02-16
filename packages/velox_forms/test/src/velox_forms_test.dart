// ignore_for_file: cascade_invocations

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velox_forms/velox_forms.dart';

void main() {
  group('VeloxFieldState', () {
    test('has default values', () {
      const state = VeloxFieldState<String>();

      expect(state.value, isNull);
      expect(state.errorText, isNull);
      expect(state.isTouched, isFalse);
      expect(state.isValidating, isFalse);
      expect(state.isValid, isTrue);
      expect(state.hasError, isFalse);
    });

    test('isValid returns true when errorText is null', () {
      const state = VeloxFieldState<String>(value: 'test');

      expect(state.isValid, isTrue);
    });

    test('hasError returns true only when errorText is set and isTouched', () {
      const untouched = VeloxFieldState<String>(errorText: 'error');
      expect(untouched.hasError, isFalse);

      const touched = VeloxFieldState<String>(
        errorText: 'error',
        isTouched: true,
      );
      expect(touched.hasError, isTrue);
    });

    test('copyWith replaces specified fields', () {
      const original = VeloxFieldState<String>(
        value: 'hello',
        errorText: 'required',
        isTouched: true,
      );

      final updated = original.copyWith(value: 'world');

      expect(updated.value, 'world');
      expect(updated.errorText, 'required');
      expect(updated.isTouched, isTrue);
    });

    test('copyWith clearError removes error text', () {
      const original = VeloxFieldState<String>(
        value: 'hello',
        errorText: 'required',
      );

      final updated = original.copyWith(clearError: true);

      expect(updated.value, 'hello');
      expect(updated.errorText, isNull);
    });
  });

  group('VeloxValidators', () {
    test('required returns error for null', () {
      final validator = VeloxValidators.required();

      expect(validator(null), 'This field is required');
    });

    test('required returns error for empty string', () {
      final validator = VeloxValidators.required();

      expect(validator(''), 'This field is required');
    });

    test('required returns null for non-empty string', () {
      final validator = VeloxValidators.required();

      expect(validator('hello'), isNull);
    });

    test('required uses custom message', () {
      final validator = VeloxValidators.required(message: 'Enter a value');

      expect(validator(''), 'Enter a value');
    });

    test('minLength returns error for short string', () {
      final validator = VeloxValidators.minLength(5);

      expect(validator('hi'), 'Must be at least 5 characters');
    });

    test('minLength returns null for long enough string', () {
      final validator = VeloxValidators.minLength(3);

      expect(validator('hello'), isNull);
    });

    test('maxLength returns error for long string', () {
      final validator = VeloxValidators.maxLength(3);

      expect(validator('hello'), 'Must be at most 3 characters');
    });

    test('maxLength returns null for short enough string', () {
      final validator = VeloxValidators.maxLength(10);

      expect(validator('hello'), isNull);
    });

    test('email returns null for valid email', () {
      final validator = VeloxValidators.email();

      expect(validator('user@example.com'), isNull);
    });

    test('email returns error for invalid email', () {
      final validator = VeloxValidators.email();

      expect(validator('not-an-email'), 'Invalid email address');
    });

    test('email returns null for empty value', () {
      final validator = VeloxValidators.email();

      expect(validator(''), isNull);
    });

    test('pattern returns null for matching value', () {
      final validator = VeloxValidators.pattern(RegExp(r'^\d+$'));

      expect(validator('123'), isNull);
    });

    test('pattern returns error for non-matching value', () {
      final validator = VeloxValidators.pattern(RegExp(r'^\d+$'));

      expect(validator('abc'), 'Invalid format');
    });

    test('match returns null when values match', () {
      final validator = VeloxValidators.match(() => 'password123');

      expect(validator('password123'), isNull);
    });

    test('match returns error when values differ', () {
      final validator = VeloxValidators.match(() => 'password123');

      expect(validator('different'), 'Values do not match');
    });

    test('compose runs all validators and returns first error', () {
      final validator = VeloxValidators.compose<String>([
        VeloxValidators.required(),
        VeloxValidators.minLength(5),
      ]);

      expect(validator(''), 'This field is required');
      expect(validator('hi'), 'Must be at least 5 characters');
      expect(validator('hello'), isNull);
    });
  });

  group('VeloxFormController', () {
    late VeloxFormController controller;

    setUp(() {
      controller = VeloxFormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('registerField creates a field with initial value', () {
      controller.registerField<String>('email', initialValue: 'test@test.com');

      final field = controller.getField<String>('email');

      expect(field, isNotNull);
      expect(field!.value, 'test@test.com');
    });

    test('getField returns null for unregistered field', () {
      final field = controller.getField<String>('nonexistent');

      expect(field, isNull);
    });

    test('setFieldValue updates value and validates', () {
      controller.registerField<String>(
        'name',
        validators: [VeloxValidators.required()],
      );

      controller.setFieldValue<String>('name', '');

      final field = controller.getField<String>('name');
      expect(field!.value, '');
      expect(field.errorText, 'This field is required');
    });

    test('setFieldValue clears error when valid', () {
      controller.registerField<String>(
        'name',
        validators: [VeloxValidators.required()],
      );

      controller.setFieldValue<String>('name', '');
      controller.setFieldValue<String>('name', 'Alice');

      final field = controller.getField<String>('name');
      expect(field!.errorText, isNull);
    });

    test('touchField marks field as touched', () {
      controller.registerField<String>('name');

      controller.touchField('name');

      final field = controller.getField<String>('name');
      expect(field!.isTouched, isTrue);
    });

    test('validate validates all fields and returns result', () {
      controller.registerField<String>(
        'email',
        validators: [VeloxValidators.required()],
      );
      controller.registerField<String>(
        'name',
        initialValue: 'Alice',
        validators: [VeloxValidators.required()],
      );

      final result = controller.validate();

      expect(result, isFalse);
      expect(
        controller.getField<String>('email')!.errorText,
        'This field is required',
      );
      expect(controller.getField<String>('name')!.errorText, isNull);
    });

    test('validate returns true when all fields are valid', () {
      controller.registerField<String>(
        'name',
        initialValue: 'Alice',
        validators: [VeloxValidators.required()],
      );

      final result = controller.validate();

      expect(result, isTrue);
    });

    test('isValid reflects current validation state', () {
      controller.registerField<String>(
        'name',
        validators: [VeloxValidators.required()],
      );

      expect(controller.isValid, isTrue);

      controller.setFieldValue<String>('name', '');
      expect(controller.isValid, isFalse);

      controller.setFieldValue<String>('name', 'Bob');
      expect(controller.isValid, isTrue);
    });

    test('values returns map of all field values', () {
      controller.registerField<String>('name', initialValue: 'Alice');
      controller.registerField<String>(
        'email',
        initialValue: 'alice@test.com',
      );

      final vals = controller.values;

      expect(vals, {'name': 'Alice', 'email': 'alice@test.com'});
    });

    test('reset clears all fields to initial values', () {
      controller.registerField<String>(
        'name',
        initialValue: 'Alice',
        validators: [VeloxValidators.required()],
      );

      controller.setFieldValue<String>('name', 'Bob');
      controller.touchField('name');
      controller.reset();

      final field = controller.getField<String>('name');
      expect(field!.value, 'Alice');
      expect(field.isTouched, isFalse);
      expect(field.errorText, isNull);
    });

    test('notifies listeners on state change', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.registerField<String>('name');
      controller.setFieldValue<String>('name', 'test');

      expect(notifyCount, 1);
    });

    test('does not register the same field twice', () {
      controller.registerField<String>('name', initialValue: 'first');
      controller.registerField<String>('name', initialValue: 'second');

      final field = controller.getField<String>('name');
      expect(field!.value, 'first');
    });
  });

  group('VeloxForm widget', () {
    testWidgets('provides controller to descendants', (tester) async {
      final controller = VeloxFormController();
      controller.registerField<String>('name', initialValue: 'Alice');

      VeloxFormController? foundController;

      await tester.pumpWidget(
        MaterialApp(
          home: VeloxForm(
            controller: controller,
            child: Builder(
              builder: (context) {
                foundController = VeloxForm.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(foundController, isNotNull);
      expect(foundController, equals(controller));
      expect(foundController!.getField<String>('name')!.value, 'Alice');

      controller.dispose();
    });

    testWidgets('returns null when no VeloxForm ancestor', (tester) async {
      VeloxFormController? foundController;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              foundController = VeloxForm.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(foundController, isNull);
    });
  });

  group('VeloxTextField widget', () {
    testWidgets('renders and registers with controller', (tester) async {
      final controller = VeloxFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeloxForm(
              controller: controller,
              child: const VeloxTextField(
                name: 'username',
                label: 'Username',
                hint: 'Enter username',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(controller.getField<String>('username'), isNotNull);

      controller.dispose();
    });

    testWidgets('updates controller on text input', (tester) async {
      final controller = VeloxFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeloxForm(
              controller: controller,
              child: const VeloxTextField(
                name: 'username',
                validators: [],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(controller.getField<String>('username')!.value, 'hello');

      controller.dispose();
    });

    testWidgets('shows validation error after touch', (tester) async {
      final controller = VeloxFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VeloxForm(
              controller: controller,
              child: VeloxTextField(
                name: 'email',
                label: 'Email',
                validators: [VeloxValidators.required()],
              ),
            ),
          ),
        ),
      );

      // Enter empty text to trigger validation
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Touch the field by calling validate on the controller
      controller.validate();
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);

      controller.dispose();
    });
  });
}
