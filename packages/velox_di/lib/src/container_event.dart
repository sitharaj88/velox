/// Events emitted by [VeloxContainer] during registration, resolution,
/// and disposal of services.
///
/// Subscribe via [VeloxContainer.events] to observe the container lifecycle
/// for debugging, logging, or metrics.
///
/// ```dart
/// container.events.listen((event) {
///   print('${event.kind}: ${event.type}');
/// });
/// ```
sealed class ContainerEvent {
  /// Creates a [ContainerEvent].
  const ContainerEvent({required this.type, this.name});

  /// The service type involved in the event.
  final Type type;

  /// The optional name tag if the registration was named.
  final String? name;
}

/// Emitted when a new service is registered in the container.
final class RegistrationEvent extends ContainerEvent {
  /// Creates a [RegistrationEvent].
  const RegistrationEvent({required super.type, super.name});

  @override
  String toString() {
    final tag = name != null ? ' (name: $name)' : '';
    return 'RegistrationEvent: $type$tag';
  }
}

/// Emitted when a service is resolved (retrieved) from the container.
final class ResolutionEvent extends ContainerEvent {
  /// Creates a [ResolutionEvent].
  const ResolutionEvent({required super.type, super.name});

  @override
  String toString() {
    final tag = name != null ? ' (name: $name)' : '';
    return 'ResolutionEvent: $type$tag';
  }
}

/// Emitted when a service instance is disposed by the container.
final class DisposalEvent extends ContainerEvent {
  /// Creates a [DisposalEvent].
  const DisposalEvent({required super.type, super.name});

  @override
  String toString() {
    final tag = name != null ? ' (name: $name)' : '';
    return 'DisposalEvent: $type$tag';
  }
}

/// Emitted when a service registration is removed (unregistered).
final class UnregistrationEvent extends ContainerEvent {
  /// Creates an [UnregistrationEvent].
  const UnregistrationEvent({required super.type, super.name});

  @override
  String toString() {
    final tag = name != null ? ' (name: $name)' : '';
    return 'UnregistrationEvent: $type$tag';
  }
}

/// Emitted when a service registration is overridden.
final class OverrideEvent extends ContainerEvent {
  /// Creates an [OverrideEvent].
  const OverrideEvent({required super.type, super.name});

  @override
  String toString() {
    final tag = name != null ? ' (name: $name)' : '';
    return 'OverrideEvent: $type$tag';
  }
}
