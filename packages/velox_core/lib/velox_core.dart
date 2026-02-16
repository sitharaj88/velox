/// Foundation package for the Velox Flutter plugin collection.
///
/// Provides:
/// - [Result] type for type-safe error handling
/// - [VeloxException] hierarchy for structured exceptions
/// - Common extensions on built-in types
/// - Platform detection utilities
library;

export 'src/exceptions/velox_exception.dart';
export 'src/extensions/date_time_extensions.dart';
export 'src/extensions/iterable_extensions.dart';
export 'src/extensions/num_extensions.dart';
export 'src/extensions/string_extensions.dart';
export 'src/platform/platform_info.dart';
export 'src/result/result.dart';
