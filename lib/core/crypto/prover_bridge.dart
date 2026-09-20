import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/zk_vote_proof.dart';
import '../config/env.dart';
import 'crypto_bridge_exception.dart';

/// WebView bridge que conecta con la ruta `/prove` de Themis Web
/// para generar pruebas ZK-SNARK (Groth16 Semaphore) de forma aislada
/// en el dispositivo del votante (CU-10).
class ProverBridge {
  ProverBridge({String? url}) : _url = url ?? Env.webProverUrl {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ThemisProverChannel', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_readyCompleter.isCompleted) {
              _readyCompleter.complete();
            }
          },
          onWebResourceError: (error) {
            if (!_readyCompleter.isCompleted) {
              _readyCompleter.completeError(
                CryptoBridgeException(
                  'No se pudo conectar con el generador de pruebas ZK en $_url: ${error.description}',
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  final String _url;
  late final WebViewController _controller;
  final Completer<void> _readyCompleter = Completer<void>();
  Completer<Map<String, dynamic>>? _pending;

  /// Debe montarse en el árbol de widgets para que el WebView esté activo.
  Widget get widget => Opacity(
        opacity: 0,
        child: SizedBox(
          width: 1,
          height: 1,
          child: WebViewWidget(controller: _controller),
        ),
      );

  Future<ZkVoteProof> generateProof({
    required String privateKey,
    required List<String> members,
    required String message,
    required String scope,
  }) async {
    await _readyCompleter.future;
    if (_pending != null) {
      throw const CryptoBridgeException('Ya hay una generación de prueba en curso');
    }

    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;

    final script = 'window.generateSemaphoreProof('
        '${jsonEncode(privateKey)}, '
        '${jsonEncode(members)}, '
        '${jsonEncode(message)}, '
        '${jsonEncode(scope)})';

    unawaited(_controller.runJavaScript(script));

    final result = await completer.future;
    if (result['ok'] != true) {
      throw CryptoBridgeException(
        result['error'] as String? ?? 'Error generando la prueba ZK',
      );
    }

    final proofMap = result['proof'] as Map<String, dynamic>;
    return ZkVoteProof.fromJson(proofMap);
  }

  void _handleMessage(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    if (_pending == null) return;
    final completer = _pending!;
    _pending = null;
    completer.complete(json);
  }
}
