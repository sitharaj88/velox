# Velox Theme

A powerful Material 3 theming engine for Flutter with dynamic color schemes,
custom typography, and seamless theme switching.

## Features

- Material 3 color scheme generation from seed colors
- Custom semantic color tokens (success, warning, info)
- Responsive typography system
- Light/dark/system theme mode support
- `VeloxThemeBuilder` widget for reactive theme switching
- Extension methods for easy theme access from `BuildContext`

## Usage

```dart
import 'package:velox_theme/velox_theme.dart';

// Create a theme configuration
final config = VeloxThemeConfig(
  seedColor: Colors.blue,
  fontFamily: 'Roboto',
);

// Use VeloxThemeBuilder in your app
VeloxThemeBuilder(
  config: config,
  initialMode: VeloxThemeMode.system,
  builder: (context, lightTheme, darkTheme, mode) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: mode.toThemeMode(),
    );
  },
);
```
