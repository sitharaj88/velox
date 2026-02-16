import 'package:velox_di/src/velox_container.dart';

/// A grouping mechanism for related dependency registrations.
///
/// Implement [VeloxModule] to bundle registrations that belong together.
/// This makes large applications easier to organise and test in isolation.
///
/// [VeloxModule] supports both the simple [register] pattern and the
/// lifecycle-aware [install] / [uninstall] pattern.
///
/// ## Simple usage with [register]
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
///
/// ## Lifecycle-aware usage with [install] / [uninstall]
///
/// ```dart
/// class NetworkModule extends VeloxModule {
///   @override
///   void register(VeloxContainer container) {
///     container.registerLazy<HttpClient>(
///       () => HttpClient(),
///       disposable: true,
///     );
///     container.registerFactory<ApiService>(
///       () => ApiService(container.get<HttpClient>()),
///     );
///   }
///
///   @override
///   void onInstall(VeloxContainer container) {
///     // Additional setup after registration
///   }
///
///   @override
///   void onUninstall(VeloxContainer container) {
///     container
///       ..unregister<ApiService>()
///       ..unregister<HttpClient>();
///   }
/// }
///
/// // Usage
/// final container = VeloxContainer();
/// final module = NetworkModule();
/// module.install(container);
/// // later...
/// module.uninstall(container);
/// ```
abstract class VeloxModule {
  bool _installed = false;

  /// Whether this module has been installed into a container.
  bool get isInstalled => _installed;

  /// Registers all dependencies provided by this module into [container].
  ///
  /// Override this method to define the registrations for this module.
  void register(VeloxContainer container);

  /// Installs this module into [container] by calling [register] and then
  /// [onInstall].
  ///
  /// Marks the module as installed. Calling [install] again without a prior
  /// [uninstall] has no effect (the module is only installed once).
  ///
  /// ```dart
  /// final module = AuthModule();
  /// module.install(container);
  /// ```
  void install(VeloxContainer container) {
    if (_installed) return;
    register(container);
    onInstall(container);
    _installed = true;
  }

  /// Uninstalls this module from [container] by calling [onUninstall].
  ///
  /// Marks the module as not installed. Calling [uninstall] without a prior
  /// [install] has no effect.
  ///
  /// ```dart
  /// module.uninstall(container);
  /// ```
  void uninstall(VeloxContainer container) {
    if (!_installed) return;
    onUninstall(container);
    _installed = false;
  }

  /// Called after [register] during [install].
  ///
  /// Override this to perform additional setup that depends on all
  /// registrations being in place.
  void onInstall(VeloxContainer container) {}

  /// Called during [uninstall] to clean up registrations and resources.
  ///
  /// Override this to remove registrations added by [register].
  void onUninstall(VeloxContainer container) {}
}
