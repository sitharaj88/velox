import 'package:meta/meta.dart';

/// Base class for all events dispatched through a [VeloxEventBus].
///
/// Every event carries a [timestamp] indicating when it was created.
/// Subclass this to define your own typed events:
///
/// ```dart
/// class UserLoggedIn extends VeloxEvent {
///   UserLoggedIn(this.userId);
///   final String userId;
/// }
/// ```
@immutable
abstract class VeloxEvent {
  /// Creates a [VeloxEvent] with the current time as its [timestamp].
  VeloxEvent() : timestamp = DateTime.now();

  /// The time at which this event was created.
  final DateTime timestamp;

  @override
  String toString() => '$runtimeType(timestamp: $timestamp)';
}
