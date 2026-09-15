import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/mock_sso_repository.dart';
import '../../domain/entities/mock_sso_assertion.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.repository});

  final MockSsoRepository repository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assertion = await widget.repository.login(
        codigoInstitucional: _codigoController.text.trim(),
        password: _passwordController.text,
      );
      final payload = MockSsoAssertionPayload.decode(assertion);

      if (!mounted) return;
      setState(() => _loading = false);
      context.push('/login/resultado', extra: payload);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.response?.statusCode == 401
            ? 'Codigo institucional o contrasena incorrectos'
            : 'No se pudo conectar con el servidor';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo conectar con el servidor';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Codigo institucional',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contrasena'),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Requerido'
                      : null,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton(
              onPressed: _submit,
              child: const Text('Ingresar'),
            ),
        ],
      ),
    );
  }
}
