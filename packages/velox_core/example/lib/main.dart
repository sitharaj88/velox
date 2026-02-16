// ignore_for_file: avoid_print, unused_local_variable
import 'package:velox_core/velox_core.dart';

void main() {
  // Result type example
  final result = divide(10, 3);
  result.when(
    success: (value) => print('Result: $value'),
    failure: (error) => print('Error: ${error.message}'),
  );

  // Chaining results
  final chained = divide(10, 2)
      .map((v) => v * 3)
      .flatMap((v) => divide(v.toInt(), 5));
  print('Chained: ${chained.valueOrNull}');

  // String extensions
  print('hello world'.capitalized); // Hello world
  print('hello world'.toCamelCase); // helloWorld
  print('helloWorld'.toSnakeCase); // hello_world
  print('test@example.com'.isEmail); // true

  // Iterable extensions
  final grouped = ['apple', 'avocado', 'banana'].groupBy((s) => s[0]);
  print('Grouped: $grouped');

  final chunks = [1, 2, 3, 4, 5].chunked(2).toList();
  print('Chunks: $chunks');

  // Num extensions
  final timeout = 30.seconds;
  print('Timeout: $timeout');
  print('5 is between 1-10: ${5.isBetween(1, 10)}');
  print('1st, 2nd, 3rd: ${1.ordinal}, ${2.ordinal}, ${3.ordinal}');
}

Result<double, VeloxException> divide(int a, int b) {
  if (b == 0) {
    return const Failure(
      VeloxException(message: 'Division by zero', code: 'DIV_ZERO'),
    );
  }
  return Success(a / b);
}
