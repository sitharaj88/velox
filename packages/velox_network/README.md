# velox_network

[![pub.dev](https://img.shields.io/pub/v/velox_network.svg)](https://pub.dev/packages/velox_network)
[![style: velox lint](https://img.shields.io/badge/style-velox__lint-blue.svg)](https://pub.dev/packages/velox_lint)

A high-performance HTTP client abstraction for Flutter with interceptors, retry logic, and Result-based error handling.

## Features

- Type-safe request/response handling with Result types
- Interceptor pipeline for request/response transformation
- Configurable retry with exponential backoff
- Built-in logging and headers interceptors
- Request cancellation support
- Zero external HTTP dependencies (uses dart:io HttpClient)

## Usage

```dart
import 'package:velox_network/velox_network.dart';

final client = VeloxHttpClient(
  config: VeloxNetworkConfig(
    baseUrl: 'https://api.example.com',
    maxRetries: 3,
    interceptors: [
      HeadersInterceptor({'Authorization': 'Bearer $token'}),
    ],
  ),
);

final result = await client.get('/users/1');
result.when(
  success: (response) => print(response.data),
  failure: (error) => print(error.message),
);
```

## Part of the Velox Collection

This package is part of the [Velox](https://github.com/velox-flutter/velox) Flutter plugin collection.
