import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/semaphore_proof.dart';
import 'crypto_bridge_exception.dart';
import 'vote_proof_generator.dart';

/// WebView que carga `$webBaseUrl/prove` (themis-web) y genera la prueba
/// zk-SNARK del voto (CU-10) sin reimplementar snarkjs en Dart -- misma
/// decision de diseno que CU-05 (ver crypto_bridge.dart), pero remoto en vez
/// de un asset local: `/prove` necesita hablar con themis-core
/// (voting-context) y con el CDN oficial de artefactos de Semaphore. Mismo
/// patron JavaScriptChannel + Completer que CryptoBridge, canal separado
/// (`ThemisVoteChannel`) porque el protocolo de esta pagina es distinto.
class VoteProofBridge implements VoteProofGenerator {
  VoteProofBridge({required String webBaseUrl}) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ThemisVoteChannel', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _readyCompleter.complete()),
      )
      ..loadRequest(Uri.parse('$webBaseUrl/prove'));
  }

  late final WebViewController _controller;
  final Completer<void> _readyCompleter = Completer<void>();
  Completer<Map<String, dynamic>>? _pending;

  /// Debe montarse en el arbol de widgets (puede ser invisible) para que el
  /// WebView funcione en todas las plataformas.
  @override
  Widget get widget => Opacity(
    opacity: 0,
    child: SizedBox(width: 1, height: 1, child: WebViewWidget(controller: _controller)),
  );

  /// [identityPrivateKey] es el mismo string ya guardado por
  /// SecureIdentityStore en CU-05 (identity.export()). [apiBaseUrl] se pasa
  /// explicito (no se lee de Env aca) para que /prove hable con el mismo
  /// backend que ya usa esta app, sin asumir un host fijo.
  ///
  /// Mejora deliberada respecto a CryptoBridge (que hoy no tiene ninguna):
  /// esta operacion depende de red (themis-core + CDN de artefactos), asi
  /// que agrega un timeout explicito en vez de poder colgar para siempre.
  @override
  Future<SemaphoreProof> generateProof({
    required String identityPrivateKey,
    required String electionId,
    required String optionId,
    required String apiBaseUrl,
  }) async {
    if (!_readyCompleter.isCompleted) await _readyCompleter.future;
    if (_pending != null) {
      throw const CryptoBridgeException('Ya hay una operacion en curso en el VoteProofBridge');
    }

    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;

    final payload = jsonEncode({
      'identityPrivateKey': identityPrivateKey,
      'electionId': electionId,
      'optionId': optionId,
      'apiBaseUrl': apiBaseUrl,
    });
    unawaited(_controller.runJavaScript('window.generateVoteProof(${jsonEncode(payload)})'));

    final result = await completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _pending = null;
        throw const CryptoBridgeException('Tiempo de espera agotado generando la prueba de voto');
      },
    );

    if (result['ok'] != true) {
      throw CryptoBridgeException(
        result['error'] as String? ?? 'Error desconocido generando la prueba de voto',
      );
    }
    return SemaphoreProof.fromJson(result['proof'] as Map<String, dynamic>);
  }

  void _handleMessage(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    if (json['type'] != 'vote-proof' || _pending == null) return;

    final completer = _pending!;
    _pending = null;
    completer.complete(json);
  }
}
