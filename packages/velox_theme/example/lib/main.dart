import 'package:flutter/material.dart';
import 'package:velox_theme/velox_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => VeloxThemeBuilder(
        config: const VeloxThemeConfig(
          seedColor: Colors.indigo,
          fontFamily: 'Roboto',
          borderRadius: 16,
        ),
        builder: (context, lightTheme, darkTheme, mode) => MaterialApp(
          title: 'Velox Theme Demo',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode.toThemeMode(),
          home: const ThemeDemo(),
        ),
      );
}

class ThemeDemo extends StatelessWidget {
  const ThemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.veloxColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velox Theme'),
        actions: [
          IconButton(
            icon: Icon(context.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => context.veloxThemeBuilder?.toggleMode(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: colors?.success),
              title: const Text('Success'),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: colors?.warning),
              title: const Text('Warning'),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: colors?.info),
              title: const Text('Info'),
            ),
          ),
        ],
      ),
    );
  }
}
