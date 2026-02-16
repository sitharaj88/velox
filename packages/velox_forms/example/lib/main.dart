// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:velox_forms/velox_forms.dart';

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating the velox_forms package.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Velox Forms Example',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const LoginPage(),
      );
}

/// A login form page built with velox_forms.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = VeloxFormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_controller.validate()) {
      final values = _controller.values;
      print('Login submitted: $values');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome, ${values['email']}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: VeloxForm(
            controller: _controller,
            onSubmit: _onSubmit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VeloxTextField(
                  name: 'email',
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validators: [
                    VeloxValidators.required(),
                    VeloxValidators.email(),
                  ],
                ),
                const SizedBox(height: 16),
                VeloxTextField(
                  name: 'password',
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                  validators: [
                    VeloxValidators.required(),
                    VeloxValidators.minLength(6),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onSubmit,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
}
