import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/mock_sso_repository.dart';
import '../../domain/entities/login_result.dart';
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
      context.push(
        '/login/resultado',
        extra: LoginResult(assertion: assertion, payload: payload),
      );
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_vote_outlined,
                  color: AppColors.onInk,
                ),
              ),
              const SizedBox(height: 24),
              Text('Bienvenido a Themis', style: textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Inicia sesion con tu SSO institucional para continuar',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card + 4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codigoController,
                          decoration: const InputDecoration(
                            labelText: 'Codigo institucional',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.stack),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contrasena',
                          ),
                          obscureText: true,
                          validator: (value) =>
                              (value == null || value.isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stack),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.card),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : FilledButton(
                        onPressed: _submit,
                        child: const Text('Ingresar'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
