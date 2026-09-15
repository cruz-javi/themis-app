import 'package:flutter/material.dart';

import '../../domain/entities/mock_sso_assertion.dart';

class LoginResultPage extends StatelessWidget {
  const LoginResultPage({super.key, required this.payload});

  final MockSsoAssertionPayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesion iniciada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        payload.habilitado ? Icons.check_circle : Icons.error,
                        color: payload.habilitado
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        payload.habilitado
                            ? 'Habilitado para votar'
                            : 'No habilitado para votar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Facultad: ${payload.facultad}'),
                  Text('Tipo de usuario: ${payload.tipoUsuario}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
