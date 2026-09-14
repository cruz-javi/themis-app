import 'package:flutter/material.dart';

import '../../data/repositories/demo_repository.dart';
import '../../domain/entities/core_health.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key, required this.repository});

  final DemoRepository repository;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  CoreHealth? _health;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final health = await widget.repository.fetchHealth();
      if (!mounted) return;
      setState(() {
        _health = health;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendPing() async {
    try {
      await widget.repository.sendPing('desde la app movil');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ping guardado en Neon')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Themis - conectividad')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No se pudo contactar a themis-core',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 8),
                      const Text(
                        'En emulador Android usa 10.0.2.2 en lugar de localhost.',
                      ),
                    ],
                  ),
                ),
              )
            else if (_health != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado: ${_health!.status}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Neon',
                        ok: _health!.databaseReachable,
                      ),
                      _StatusRow(
                        label: 'Blockchain',
                        ok: _health!.chainConnected,
                      ),
                      _StatusRow(label: 'themis-ai', ok: _health!.aiReachable),
                      const SizedBox(height: 8),
                      Text('Contrato: ${_health!.contractVersion ?? '-'}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sendPing,
              child: const Text('Escribir ping en Neon'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _refresh,
              child: const Text('Refrescar estado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error,
            size: 18,
            color: ok ? Colors.green.shade700 : Colors.red.shade700,
            semanticLabel: ok ? 'conectado' : 'sin conexion',
          ),
          const SizedBox(width: 8),
          Text('$label: ${ok ? 'conectado' : 'sin conexion'}'),
        ],
      ),
    );
  }
}
