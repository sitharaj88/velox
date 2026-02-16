# velox_responsive

A responsive layout system for Flutter with breakpoint-aware widgets, responsive grid, adaptive sizing, and platform detection.

## Features

- **VeloxBreakpoint** - Named breakpoints for mobile, tablet, desktop, and wide screens.
- **VeloxResponsiveBuilder** - A widget that rebuilds based on the current breakpoint.
- **VeloxResponsiveValue** - Per-breakpoint values with automatic fallback to smaller breakpoints.
- **VeloxResponsiveGrid** - A responsive grid layout with configurable column counts per breakpoint.
- **VeloxResponsivePadding** - Applies different padding per breakpoint.
- **VeloxScreenInfo** - A `BuildContext` extension for quick access to screen dimensions and breakpoint queries.

## Usage

```dart
import 'package:velox_responsive/velox_responsive.dart';

// Responsive builder
VeloxResponsiveBuilder(
  builder: (context, breakpoint, constraints) {
    return switch (breakpoint) {
      VeloxBreakpoint.mobile => const MobileLayout(),
      VeloxBreakpoint.tablet => const TabletLayout(),
      _ => const DesktopLayout(),
    };
  },
)

// Responsive values
const columns = VeloxResponsiveValue<int>(
  mobile: 1,
  tablet: 2,
  desktop: 3,
  wide: 4,
);

// Screen info extension
if (context.isMobile) {
  // mobile-specific logic
}
```
