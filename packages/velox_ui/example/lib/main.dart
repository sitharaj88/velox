import 'package:flutter/material.dart';
import 'package:velox_ui/velox_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => VeloxThemeBuilder(
        config: const VeloxThemeConfig(seedColor: Colors.indigo),
        builder: (context, light, dark, mode) => MaterialApp(
          theme: light,
          darkTheme: dark,
          themeMode: mode.toThemeMode(),
          home: const HomePage(),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Velox UI')),
        body: VeloxStaggeredList(
          children: [
            VeloxButton(
              label: 'Filled Button',
              onPressed: () {},
            ),
            VeloxLoadingButton(
              label: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
          ],
        ),
      );
}
