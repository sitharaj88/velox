/// Enumeration of supported permission types.
///
/// Each value represents a system permission that can be requested
/// from the user on various platforms.
///
/// ```dart
/// final type = VeloxPermissionType.camera;
/// print(type.displayName); // 'Camera'
/// ```
enum VeloxPermissionType {
  /// Permission to access the device camera.
  camera,

  /// Permission to access the device microphone.
  microphone,

  /// Permission to access the device location (while in use).
  location,

  /// Permission to access the device location at all times.
  locationAlways,

  /// Permission to access device storage (files, downloads).
  storage,

  /// Permission to access photos and media library.
  photos,

  /// Permission to access the user's contacts.
  contacts,

  /// Permission to access the user's calendar.
  calendar,

  /// Permission to display notifications.
  notifications,

  /// Permission to access phone call functionality.
  phone,

  /// Permission to send and read SMS messages.
  sms,

  /// Permission to use Bluetooth.
  bluetooth,

  /// Permission to access device sensors (e.g., accelerometer).
  sensors;

  /// Returns a human-readable display name for this permission type.
  ///
  /// ```dart
  /// VeloxPermissionType.locationAlways.displayName; // 'Location Always'
  /// VeloxPermissionType.sms.displayName; // 'SMS'
  /// ```
  String get displayName => switch (this) {
        VeloxPermissionType.camera => 'Camera',
        VeloxPermissionType.microphone => 'Microphone',
        VeloxPermissionType.location => 'Location',
        VeloxPermissionType.locationAlways => 'Location Always',
        VeloxPermissionType.storage => 'Storage',
        VeloxPermissionType.photos => 'Photos',
        VeloxPermissionType.contacts => 'Contacts',
        VeloxPermissionType.calendar => 'Calendar',
        VeloxPermissionType.notifications => 'Notifications',
        VeloxPermissionType.phone => 'Phone',
        VeloxPermissionType.sms => 'SMS',
        VeloxPermissionType.bluetooth => 'Bluetooth',
        VeloxPermissionType.sensors => 'Sensors',
      };
}
