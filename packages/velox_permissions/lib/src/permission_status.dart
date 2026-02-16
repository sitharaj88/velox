/// Enumeration of possible permission states.
///
/// Represents the current status of a permission after checking or
/// requesting it from the platform.
///
/// ```dart
/// final status = VeloxPermissionStatus.granted;
/// print(status.isGranted); // true
/// print(status.canRequest); // true
/// ```
enum VeloxPermissionStatus {
  /// The permission has been granted by the user.
  granted,

  /// The permission has been denied by the user.
  ///
  /// The permission can still be requested again.
  denied,

  /// The permission has been permanently denied by the user.
  ///
  /// The user must manually enable the permission in system settings.
  permanentlyDenied,

  /// The permission is restricted by the operating system.
  ///
  /// This is typically an iOS-specific status where parental controls
  /// or device management profiles prevent the permission from being granted.
  restricted,

  /// The permission has been granted with limited access.
  ///
  /// For example, access to only selected photos instead of the full library.
  limited,

  /// The permission status is unknown or has not been determined.
  unknown;

  /// Whether this status represents a granted permission.
  ///
  /// Returns `true` for [granted] and [limited].
  bool get isGranted => this == granted || this == limited;

  /// Whether this status represents a denied permission.
  ///
  /// Returns `true` for [denied] and [permanentlyDenied].
  bool get isDenied => this == denied || this == permanentlyDenied;

  /// Whether a permission request can be made.
  ///
  /// Returns `true` if the permission is not [permanentlyDenied]
  /// or [restricted], as those states require the user to manually
  /// change settings.
  bool get canRequest => this != permanentlyDenied && this != restricted;
}
