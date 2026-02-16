# Velox UI

The complete Velox UI toolkit. A single import that gives you access to all
Velox UI packages.

## Included Packages

| Package | Description |
|---------|-------------|
| `velox_theme` | Material 3 theming engine |
| `velox_responsive` | Responsive layout system |
| `velox_buttons` | Advanced button components |
| `velox_animations` | Physics-based animation toolkit |
| `velox_forms` | Declarative form builder |
| `velox_charts` | High-performance data visualization |

## Usage

```dart
import 'package:velox_ui/velox_ui.dart';

// Now you have access to everything:
// VeloxThemeBuilder, VeloxResponsiveBuilder, VeloxButton,
// VeloxFadeIn, VeloxForm, VeloxLineChart, etc.
```

## Tree Shaking

Even though this package re-exports all UI packages, Dart's tree shaking
ensures only the code you actually use ends up in your final build.
