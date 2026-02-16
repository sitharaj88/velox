# Velox Buttons

Advanced button components for Flutter including gradient, loading state, icon, and grouped buttons with full Material 3 support.

## Features

- **VeloxButton** - Base button with filled, outlined, text, and tonal variants
- **VeloxLoadingButton** - Button with built-in loading state and progress indicator
- **VeloxGradientButton** - Button with customizable gradient backgrounds
- **VeloxIconButton** - Enhanced icon button with badge support
- **VeloxButtonGroup** - Layout multiple buttons with consistent spacing
- Three size options: small, medium, and large
- Full const constructor support

## Usage

```dart
import 'package:velox_buttons/velox_buttons.dart';

// Basic button
VeloxButton(
  label: 'Click Me',
  onPressed: () {},
)

// Loading button
VeloxLoadingButton(
  label: 'Submit',
  isLoading: true,
  onPressed: () {},
)

// Gradient button
VeloxGradientButton(
  label: 'Gradient',
  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
  onPressed: () {},
)

// Icon button with badge
VeloxIconButton(
  icon: Icons.notifications,
  showBadge: true,
  badgeLabel: '5',
  onPressed: () {},
)

// Button group
VeloxButtonGroup(
  children: [
    VeloxButton(label: 'One'),
    VeloxButton(label: 'Two'),
  ],
)
```
