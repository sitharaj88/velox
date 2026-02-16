# Velox

A world-class collection of high-performance Flutter plugins.

[![CI](https://github.com/velox-flutter/velox/actions/workflows/ci.yaml/badge.svg)](https://github.com/velox-flutter/velox/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)

## Packages

### Foundation

| Package | Description | pub.dev |
|---------|-------------|---------|
| [velox_core](packages/velox_core/) | Result types, extensions, exceptions | [![pub.dev](https://img.shields.io/pub/v/velox_core.svg)](https://pub.dev/packages/velox_core) |
| [velox_lint](packages/velox_lint/) | Custom analysis rules | [![pub.dev](https://img.shields.io/pub/v/velox_lint.svg)](https://pub.dev/packages/velox_lint) |

### Core Utilities

| Package | Description | pub.dev |
|---------|-------------|---------|
| velox_logger | Structured logging | Coming soon |
| velox_network | HTTP client abstraction | Coming soon |
| velox_storage | Local persistence | Coming soon |
| velox_cache | Intelligent caching | Coming soon |
| velox_state | State management | Coming soon |
| velox_di | Dependency injection | Coming soon |
| velox_event_bus | Typed event dispatch | Coming soon |

### UI Components

| Package | Description | pub.dev |
|---------|-------------|---------|
| velox_theme | Theming engine | Coming soon |
| velox_responsive | Responsive layouts | Coming soon |
| velox_buttons | Advanced buttons | Coming soon |
| velox_animations | Animation toolkit | Coming soon |
| velox_forms | Form builder | Coming soon |
| velox_charts | Data visualization | Coming soon |
| velox_ui | Umbrella UI package | Coming soon |

### Platform Services

| Package | Description | pub.dev |
|---------|-------------|---------|
| velox_permissions | Cross-platform permissions | Coming soon |
| velox_device | Device information | Coming soon |
| velox_biometrics | Biometric authentication | Coming soon |
| velox_connectivity | Network monitoring | Coming soon |

## Getting Started

```yaml
dependencies:
  velox_core: ^0.1.0
```

## Architecture

Velox follows these principles:

- **Performance-first**: const constructors, RepaintBoundary isolation, Isolate-based computation
- **Tree-shakeable**: Selective exports, no blind barrel files
- **Minimal dependencies**: velox_core has zero third-party dependencies
- **Consistent API**: VeloxXxx naming, Result-based error handling, config objects
- **Testability**: Constructor injection, mockable platform interfaces

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT - see [LICENSE](LICENSE) for details.
