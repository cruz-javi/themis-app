import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/vote_repository.dart';
import '../../domain/entities/public_election.dart';

/// Selector de eleccion generico contra GET /elections/public (CU-10, y
/// reusado por el flujo de registro tras el login -- antes de esto
/// login_result_page.dart usaba un electionId hardcodeado porque no existia
/// ningun listado publico de elecciones).
class ElectionSelectPage extends StatefulWidget {
  const ElectionSelectPage({
    super.key,
    required this.repository,
    required this.title,
    required this.estado,
    required this.onSelect,
  });

  final VoteRepository repository;
  final String title;
  final String estado;
  final void Function(BuildContext context, PublicElection election) onSelect;

  @override
  State<ElectionSelectPage> createState() => _ElectionSelectPageState();
}

class _ElectionSelectPageState extends State<ElectionSelectPage> {
  late final Future<List<PublicElection>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchPublicElections(estado: widget.estado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: FutureBuilder<List<PublicElection>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('No se pudieron cargar las elecciones.'),
              );
            }
            final elections = snapshot.data ?? const <PublicElection>[];
            if (elections.isEmpty) {
              return const Center(
                child: Text('No hay elecciones disponibles ahora mismo.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: elections.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stack),
              itemBuilder: (context, index) {
                final election = elections[index];
                return Card(
                  child: ListTile(
                    title: Text(election.nombre),
                    subtitle: election.descripcion != null
                        ? Text(election.descripcion!)
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => widget.onSelect(context, election),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
