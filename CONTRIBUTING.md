# Contributing to Velox

Thank you for your interest in contributing to Velox!

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (stable channel)
- [Melos](https://melos.invertase.dev/) (`dart pub global activate melos`)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/velox-flutter/velox.git
   cd velox
   ```

2. Bootstrap the workspace:
   ```bash
   melos bootstrap
   ```

## Development

### Running analysis
```bash
melos run analyze
```

### Running tests
```bash
melos run test
```

### Formatting code
```bash
melos run format:fix
```

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test changes
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

Scope with the package name: `feat(velox_core): add Result.map extension`

## Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run `melos run analyze && melos run format && melos run test`
5. Commit with conventional commit messages
6. Push and create a pull request

## Package Structure

Every package follows this layout:

```
velox_xxx/
├── lib/
│   ├── velox_xxx.dart        # Public API exports
│   └── src/                  # Private implementation
├── test/
├── example/
│   └── lib/main.dart
├── README.md
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── analysis_options.yaml
```
