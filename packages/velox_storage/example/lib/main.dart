// ignore_for_file: avoid_print
import 'package:velox_storage/velox_storage.dart';

Future<void> main() async {
  final storage = VeloxStorage(adapter: MemoryStorageAdapter());

  // Listen for changes
  storage.onChange.listen(
    (entry) => print('Changed: ${entry.key} = ${entry.value}'),
  );

  // Write typed values
  await storage.setString('name', 'John');
  await storage.setInt('age', 25);
  await storage.setBool('active', value: true);
  await storage.setJson('profile', {'role': 'admin', 'level': 5});

  // Read typed values
  print('Name: ${await storage.getString('name')}');
  print('Age: ${await storage.getInt('age')}');
  print('Active: ${await storage.getBool('active')}');
  print('Profile: ${await storage.getJson('profile')}');

  // Result-based access
  final result = await storage.getOrFail('name');
  result.when(
    success: (value) => print('Found: $value'),
    failure: (error) => print('Error: ${error.message}'),
  );

  await storage.dispose();
}
