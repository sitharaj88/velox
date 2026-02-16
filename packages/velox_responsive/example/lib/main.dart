import 'package:flutter/material.dart';
import 'package:velox_responsive/velox_responsive.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Velox Responsive Example',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const ResponsiveHomePage(),
      );
}

class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Velox Responsive')),
        body: VeloxResponsivePadding(
          padding: const VeloxResponsiveValue<EdgeInsets>(
            mobile: EdgeInsets.all(8),
            tablet: EdgeInsets.all(16),
            desktop: EdgeInsets.all(24),
            wide: EdgeInsets.all(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloxResponsiveBuilder(
                builder: (context, breakpoint, constraints) => Text(
                  'Breakpoint: ${breakpoint.name} '
                  '(${constraints.maxWidth.toStringAsFixed(0)}px)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => Text(
                  'Screen: ${context.screenWidth.toStringAsFixed(0)} x '
                  '${context.screenHeight.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: VeloxResponsiveGrid(
                  columns: const VeloxResponsiveValue<int>(
                    mobile: 2,
                    tablet: 3,
                    desktop: 4,
                    wide: 6,
                  ),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 12; i++)
                      VeloxGridItem(
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Item $i'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
