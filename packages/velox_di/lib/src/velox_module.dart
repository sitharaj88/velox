import 'package:velox_di/src/velox_container.dart';

/// A grouping mechanism for related dependency registrations.
///
/// Implement [VeloxModule] to bundle registrations that belong together.
/// This makes large applications easier to organise and test in isolation.
///
/// ```dart
/// class AuthModule extends VeloxModule {
///   @override
///   void register(VeloxContainer container) {
///     container.registerLazy<AuthService>(() => AuthServiceImpl());
///     container.registerFactory<LoginUseCase>(
///       () => LoginUseCase(container.get<AuthService>()),
///     );
///   }
/// }
///
/// // Usage
/// final container = VeloxContainer();
/// AuthModule().register(container);
/// ```
abstract class VeloxModule {
  /// Registers all dependencies provided by this module into [container].
  void register(VeloxContainer container);
}
