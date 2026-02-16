import 'dart:async';

import 'package:velox_event_bus/src/velox_event.dart';
import 'package:velox_event_bus/src/velox_event_bus.dart';

/// A scoped event bus that inherits events from a [parent] bus.
///
/// Events fired on the parent bus are forwarded to listeners on this child
/// bus. Events fired on the child bus are delivered only to child listeners
/// and are NOT propagated to the parent.
///
/// This enables hierarchical event scoping where:
/// - Global events from the parent reach all children
/// - Local events on a child stay isolated from parent and siblings
///
/// ```dart
/// final parent = VeloxEventBus();
/// final child = ScopedEventBus(parent);
///
/// child.on<UserLoggedIn>().listen((e) => print('child got it'));
///
/// parent.fire(UserLoggedIn('u1')); // child listener fires
/// child.fire(UserLoggedIn('u2'));  // only child listener fires
///
/// child.dispose(); // disposes child only, parent stays alive
/// ```
class ScopedEventBus extends VeloxEventBus {
  /// Creates a [ScopedEventBus] that inherits events from [parent].
  ///
  /// [historySize] controls the local history buffer for this child bus.
  ScopedEventBus(this.parent, {super.historySize}) {
    _parentSubscription = parent.on<VeloxEvent>().listen(_onParentEvent);
  }

  /// The parent event bus whose events are forwarded to this child.
  final VeloxEventBus parent;

  late final StreamSubscription<VeloxEvent> _parentSubscription;

  void _onParentEvent(VeloxEvent event) {
    if (isDisposed) return;
    // Forward parent events into the child bus's stream and handler pipeline,
    // bypassing interceptors (parent already applied them).
    injectEvent(event);
  }

  @override
  Future<void> dispose() async {
    await _parentSubscription.cancel();
    await super.dispose();
  }
}
