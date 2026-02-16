# velox_forms

A declarative form builder for Flutter with built-in validation, async validators, and reactive state management.

## Features

- **VeloxFieldState** - Immutable field state model with value, error, and touch tracking.
- **VeloxValidators** - Common validators: required, minLength, maxLength, email, pattern, match, compose.
- **VeloxFormController** - Manages form state, field registration, validation, and reset.
- **VeloxForm** - Widget that provides a controller to descendants via `VeloxForm.of(context)`.
- **VeloxTextField** - Text field that auto-registers with the nearest form controller.

## Usage

```dart
import 'package:velox_forms/velox_forms.dart';

final controller = VeloxFormController();

VeloxForm(
  controller: controller,
  child: Column(
    children: [
      VeloxTextField(
        name: 'email',
        label: 'Email',
        validators: [
          VeloxValidators.required(),
          VeloxValidators.email(),
        ],
      ),
      VeloxTextField(
        name: 'password',
        label: 'Password',
        obscureText: true,
        validators: [
          VeloxValidators.required(),
          VeloxValidators.minLength(6),
        ],
      ),
      ElevatedButton(
        onPressed: () {
          if (controller.validate()) {
            print(controller.values);
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
);
```
