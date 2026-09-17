import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/blinded_message.dart';
import '../../domain/entities/semaphore_identity.dart';
import 'crypto_bridge_exception.dart';

/// WebView invisible que carga `assets/semaphore/identity.html`
/// (identity.bundle.js: @semaphore-protocol/identity + @cloudflare/blindrsa-ts,
/// ver tool/semaphore-identity-bundle/) y expone la generacion de identidad
/// Semaphore y el cegado/descegado RSA (RFC 9474, CU-05) sin salir del
/// dispositivo. Un solo JavaScriptChannel, las respuestas se enrutan por un
/// campo "type" ya que las tres operaciones comparten el mismo canal.
class CryptoBridge {
  CryptoBridge() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ThemisIdentityChannel', onMessageReceived: _handleMessage)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _readyCompleter.complete()),
      )
      ..loadFlutterAsset('assets/semaphore/identity.html');
  }

  late final WebViewController _controller;
  final Completer<void> _readyCompleter = Completer<void>();
  Completer<Map<String, dynamic>>? _pending;
  String? _pendingType;

  /// Debe montarse en el arbol de widgets (puede ser invisible) para que el
  /// WebView funcione en todas las plataformas.
  Widget get widget => Opacity(
    opacity: 0,
    child: SizedBox(width: 1, height: 1, child: WebViewWidget(controller: _controller)),
  );

  Future<Map<String, dynamic>> _call(String type, String javaScript) async {
    if (!_readyCompleter.isCompleted) await _readyCompleter.future;
    if (_pending != null) {
      throw const CryptoBridgeException('Ya hay una operacion en curso en el CryptoBridge');
    }

    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;
    _pendingType = type;
    unawaited(_controller.runJavaScript(javaScript));
    final result = await completer.future;

    if (result['ok'] != true) {
      throw CryptoBridgeException(
        result['error'] as String? ?? 'Error desconocido en $type',
      );
    }
    return result;
  }

  void _handleMessage(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    if (json['type'] != _pendingType || _pending == null) return;

    final completer = _pending!;
    _pending = null;
    _pendingType = null;
    completer.complete(json);
  }

  /// Solo [seed] se usa en pruebas de reproducibilidad; en uso real se omite.
  Future<SemaphoreIdentity> generateIdentity({String? seed}) async {
    final seedArg = seed == null ? '' : jsonEncode(seed);
    final json = await _call('identity', 'window.generateIdentity($seedArg)');
    return SemaphoreIdentity(
      privateKey: json['privateKey'] as String,
      commitment: json['commitment'] as String,
    );
  }

  Future<BlindedMessage> blindCommitment({
    required String publicKeyJwk,
    required String commitment,
  }) async {
    final json = await _call(
      'blind',
      'window.blindCommitment(${jsonEncode(publicKeyJwk)}, ${jsonEncode(commitment)})',
    );
    return BlindedMessage(
      blindedMessage: json['blindedMessage'] as String,
      preparedMessage: json['preparedMsg'] as String,
      inv: json['inv'] as String,
    );
  }

  Future<String> finalizeCredential({
    required String publicKeyJwk,
    required String preparedMessage,
    required String blindSignature,
    required String inv,
  }) async {
    final json = await _call(
      'finalize',
      'window.finalizeCredential(${jsonEncode(publicKeyJwk)}, ${jsonEncode(preparedMessage)}, '
          '${jsonEncode(blindSignature)}, ${jsonEncode(inv)})',
    );
    return json['signature'] as String;
  }
}
