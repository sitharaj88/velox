import 'package:flutter/material.dart';
import 'package:velox_buttons/velox_buttons.dart';

void main() {
  runApp(const VeloxButtonsExample());
}

class VeloxButtonsExample extends StatelessWidget {
  const VeloxButtonsExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Velox Buttons Example',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const ButtonShowcase(),
      );
}

class ButtonShowcase extends StatelessWidget {
  const ButtonShowcase({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Velox Buttons')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Button Variants',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxButtonGroup(
                children: [
                  VeloxButton(label: 'Filled'),
                  VeloxButton(
                    label: 'Outlined',
                    variant: VeloxButtonVariant.outlined,
                  ),
                  VeloxButton(
                    label: 'Text',
                    variant: VeloxButtonVariant.text,
                  ),
                  VeloxButton(
                    label: 'Tonal',
                    variant: VeloxButtonVariant.tonal,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Button Sizes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxButtonGroup(
                children: [
                  VeloxButton(
                    label: 'Small',
                    size: VeloxButtonSize.small,
                  ),
                  VeloxButton(label: 'Medium'),
                  VeloxButton(
                    label: 'Large',
                    size: VeloxButtonSize.large,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Button with Icon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxButton(
                label: 'Add Item',
                icon: Icons.add,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Button',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxLoadingButton(
                label: 'Submitting...',
                isLoading: true,
              ),
              const SizedBox(height: 24),
              Text(
                'Gradient Button',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxGradientButton(
                label: 'Gradient',
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Icon Buttons',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const VeloxButtonGroup(
                children: [
                  VeloxIconButton(
                    icon: Icons.favorite,
                    tooltip: 'Favorite',
                  ),
                  VeloxIconButton(
                    icon: Icons.notifications,
                    showBadge: true,
                    badgeLabel: '3',
                  ),
                  VeloxIconButton(
                    icon: Icons.settings,
                    variant: VeloxButtonVariant.outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
