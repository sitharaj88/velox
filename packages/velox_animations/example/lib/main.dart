import 'package:flutter/material.dart';
import 'package:velox_animations/velox_animations.dart';

void main() {
  runApp(const VeloxAnimationsExample());
}

/// Example app demonstrating velox_animations widgets.
class VeloxAnimationsExample extends StatelessWidget {
  /// Creates a [VeloxAnimationsExample].
  const VeloxAnimationsExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Velox Animations Demo',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const AnimationDemoPage(),
      );
}

/// A page that demonstrates various animation widgets.
class AnimationDemoPage extends StatefulWidget {
  /// Creates an [AnimationDemoPage].
  const AnimationDemoPage({super.key});

  @override
  State<AnimationDemoPage> createState() => _AnimationDemoPageState();
}

class _AnimationDemoPageState extends State<AnimationDemoPage> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Velox Animations')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fade In:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const VeloxFadeIn(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('I fade in!'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Slide In (from left):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const VeloxSlideIn(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('I slide in from the left!'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scale In:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const VeloxScaleIn(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('I scale in!'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Shimmer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const VeloxShimmer(
                child: SizedBox(
                  width: 200,
                  height: 20,
                  child: ColoredBox(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Staggered List:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const VeloxStaggeredList(
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                  Text('Item 4'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Animated Switcher:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              VeloxAnimatedSwitcher(
                transition: VeloxSwitchTransition.scale,
                child: _showFirst
                    ? const Text('Widget A', key: ValueKey('a'))
                    : const Text('Widget B', key: ValueKey('b')),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {
                  _showFirst = !_showFirst;
                }),
                child: const Text('Toggle'),
              ),
            ],
          ),
        ),
      );
}
