# velox_animations

A physics-based animation toolkit for Flutter with fade, slide, scale, shimmer, and staggered list animations.

## Features

- **VeloxFadeIn / VeloxFadeOut** - Fade transitions with configurable duration, delay, and curve.
- **VeloxSlideIn** - Slide-in animation from any direction (left, right, top, bottom).
- **VeloxScaleIn** - Scale-in animation with configurable starting scale.
- **VeloxShimmer** - Shimmer loading effect with customizable colors.
- **VeloxStaggeredList** - Staggered fade and slide animations for lists.
- **VeloxAnimatedSwitcher** - Enhanced AnimatedSwitcher with fade, scale, slideUp, and slideDown transitions.

## Usage

```dart
import 'package:velox_animations/velox_animations.dart';

// Fade in a widget
VeloxFadeIn(
  duration: Duration(milliseconds: 500),
  child: Text('Hello'),
);

// Slide in from the right
VeloxSlideIn(
  direction: VeloxSlideDirection.right,
  child: Text('Sliding'),
);

// Shimmer loading placeholder
VeloxShimmer(
  child: Container(width: 200, height: 20, color: Colors.grey),
);

// Staggered list animation
VeloxStaggeredList(
  children: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
  ],
);
```
