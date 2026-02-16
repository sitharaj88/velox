import 'dart:async';
import 'dart:collection';

// ignore_for_file: unawaited_futures

/// A request queue that limits the number of concurrent HTTP requests
/// and optionally rate-limits requests.
///
/// ```dart
/// final queue = VeloxRequestQueue(maxConcurrent: 3);
///
/// // All these are queued and executed with at most 3 concurrent:
/// final futures = urls.map((url) =>
///   queue.add(() => client.get(url))
/// );
/// await Future.wait(futures);
///
/// queue.dispose();
/// ```
class VeloxRequestQueue {
  /// Creates a [VeloxRequestQueue].
  ///
  /// [maxConcurrent] is the maximum number of requests that can execute
  /// simultaneously. [rateLimitDelay] is an optional minimum delay
  /// between starting consecutive requests.
  VeloxRequestQueue({
    required this.maxConcurrent,
    this.rateLimitDelay,
  }) : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  /// Maximum number of concurrent requests.
  final int maxConcurrent;

  /// Optional minimum delay between starting consecutive requests.
  final Duration? rateLimitDelay;

  int _activeCount = 0;
  final Queue<_QueueEntry<dynamic>> _queue = Queue<_QueueEntry<dynamic>>();
  bool _disposed = false;
  DateTime? _lastStartTime;

  /// Number of requests currently executing.
  int get activeCount => _activeCount;

  /// Number of requests waiting in the queue.
  int get pendingCount => _queue.length;

  /// Whether this queue has been disposed.
  bool get isDisposed => _disposed;

  /// Adds a request to the queue and returns a future with the result.
  ///
  /// The request will be executed when a slot becomes available.
  Future<T> add<T>(Future<T> Function() action) {
    if (_disposed) {
      throw StateError('Cannot add requests to a disposed queue');
    }

    final completer = Completer<T>();
    _queue.add(_QueueEntry<T>(action: action, completer: completer));
    _processQueue();
    return completer.future;
  }

  /// Disposes the queue. Pending requests are completed with errors.
  void dispose() {
    _disposed = true;
    while (_queue.isNotEmpty) {
      final entry = _queue.removeFirst();
      entry.completer.completeError(
        StateError('Queue disposed while request was pending'),
      );
    }
  }

  Future<void> _processQueue() async {
    while (_queue.isNotEmpty && _activeCount < maxConcurrent && !_disposed) {
      // Apply rate limiting
      if (rateLimitDelay != null && _lastStartTime != null) {
        final elapsed = DateTime.now().difference(_lastStartTime!);
        if (elapsed < rateLimitDelay!) {
          final waitTime = rateLimitDelay! - elapsed;
          await Future<void>.delayed(waitTime);
          if (_disposed) return;
        }
      }

      if (_queue.isEmpty) return;

      final entry = _queue.removeFirst();
      _activeCount++;
      _lastStartTime = DateTime.now();

      _executeEntry(entry);
    }
  }

  Future<void> _executeEntry<T>(_QueueEntry<T> entry) async {
    try {
      final result = await entry.action();
      if (!entry.completer.isCompleted) {
        entry.completer.complete(result);
      }
    } on Object catch (e, s) {
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(e, s);
      }
    } finally {
      _activeCount--;
      _processQueue();
    }
  }
}

class _QueueEntry<T> {
  _QueueEntry({required this.action, required this.completer});

  final Future<T> Function() action;
  final Completer<T> completer;
}
