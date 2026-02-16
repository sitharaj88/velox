import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Immutable data class representing screen information.
///
/// Contains physical screen dimensions ([width] and [height]), the
/// [pixelRatio], and computed properties for logical dimensions,
/// orientation, and diagonal size.
///
/// ```dart
/// final screen = VeloxScreenInfo(
///   width: 1080,
///   height: 1920,
///   pixelRatio: 3.0,
/// );
/// print(screen.logicalWidth); // 360.0
/// print(screen.isPortrait); // true
/// print(screen.diagonal); // ~2203.0
/// ```
@immutable
class VeloxScreenInfo {
  /// Creates a [VeloxScreenInfo] with the given physical dimensions
  /// and pixel ratio.
  ///
  /// - [width] is the physical width of the screen in pixels.
  /// - [height] is the physical height of the screen in pixels.
  /// - [pixelRatio] is the device pixel ratio (physical pixels per
  ///   logical pixel).
  const VeloxScreenInfo({
    required this.width,
    required this.height,
    required this.pixelRatio,
  });

  /// The physical width of the screen in pixels.
  final double width;

  /// The physical height of the screen in pixels.
  final double height;

  /// The device pixel ratio (physical pixels per logical pixel).
  final double pixelRatio;

  /// The diagonal size of the screen in physical pixels.
  ///
  /// Computed as `sqrt(width^2 + height^2)`.
  double get diagonal => math.sqrt(width * width + height * height);

  /// The logical width of the screen (physical width divided by pixel ratio).
  double get logicalWidth => width / pixelRatio;

  /// The logical height of the screen (physical height divided by pixel ratio).
  double get logicalHeight => height / pixelRatio;

  /// Whether the screen is in portrait orientation (height > width).
  bool get isPortrait => height > width;

  /// Whether the screen is in landscape orientation (width > height).
  bool get isLandscape => width > height;

  /// Creates a copy of this [VeloxScreenInfo] with the given fields replaced.
  VeloxScreenInfo copyWith({
    double? width,
    double? height,
    double? pixelRatio,
  }) =>
      VeloxScreenInfo(
        width: width ?? this.width,
        height: height ?? this.height,
        pixelRatio: pixelRatio ?? this.pixelRatio,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeloxScreenInfo &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          pixelRatio == other.pixelRatio;

  @override
  int get hashCode => Object.hash(width, height, pixelRatio);

  @override
  String toString() =>
      'VeloxScreenInfo(width: $width, height: $height, pixelRatio: $pixelRatio)';
}
