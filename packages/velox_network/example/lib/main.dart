// ignore_for_file: avoid_print
import 'package:velox_network/velox_network.dart';

Future<void> main() async {
  final client = VeloxHttpClient(
    config: VeloxNetworkConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      maxRetries: 2,
      interceptors: [
        HeadersInterceptor({'Accept': 'application/json'}),
        LoggingInterceptor(onLog: print),
      ],
    ),
  );

  // GET request
  final result = await client.get('/posts/1');
  result.when(
    success: (response) {
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
    },
    failure: (error) {
      print('Error: ${error.message}');
    },
  );

  client.dispose();
}
