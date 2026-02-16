// ignore_for_file: avoid_print
import 'package:velox_logger/velox_logger.dart';

void main() {
  // Basic logging
  final logger = VeloxLogger(tag: 'App', minLevel: LogLevel.debug);

  logger
    ..info('Application started')
    ..debug('Loading configuration');

  // Child logger
  final authLogger = logger.child('Auth');
  authLogger.info('User authenticated');

  // Error logging
  try {
    throw Exception('Something went wrong');
  } on Exception catch (e, st) {
    logger.error('Unexpected error', error: e, stackTrace: st);
  }

  // Memory output for testing
  final memoryOutput = MemoryLogOutput();
  final testLogger = VeloxLogger(output: memoryOutput);
  testLogger.info('This is captured in memory');
  print('Captured ${memoryOutput.records.length} log records');

  logger.dispose();
}
