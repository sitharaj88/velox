# velox_lint

[![pub.dev](https://img.shields.io/pub/v/velox_lint.svg)](https://pub.dev/packages/velox_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Strict, opinionated lint rules for the Velox Flutter plugin collection.

## Usage

Add `velox_lint` to your `dev_dependencies`:

```yaml
dev_dependencies:
  velox_lint: ^0.1.0
```

Then include it in your `analysis_options.yaml`:

```yaml
include: package:velox_lint/analysis_options.yaml
```

## What's Included

- Extends `flutter_lints` with additional strict rules
- Enables strict casts, strict inference, and strict raw types
- Enforces `const` constructors and declarations
- Requires trailing commas for better diffs
- Enforces single quotes
- Prevents common mistakes (`avoid_print`, `unawaited_futures`, etc.)
- Sorts constructors and directives consistently

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.
