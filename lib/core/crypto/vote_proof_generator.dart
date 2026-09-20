import 'package:flutter/material.dart';

import '../../domain/entities/semaphore_proof.dart';

/// Interfaz de VoteProofBridge -- existe para poder inyectar un fake en
/// tests de widget (BallotPage), ya que la implementacion real depende de un
/// WebView real (no simulable con `flutter test`). A diferencia de
/// CryptoBridge (CU-05), que se instancia directo dentro de la pagina.
abstract class VoteProofGenerator {
  Future<SemaphoreProof> generateProof({
    required String identityPrivateKey,
    required String electionId,
    required String optionId,
    required String apiBaseUrl,
  });

  /// Debe montarse en el arbol de widgets para que la implementacion real
  /// (WebView) funcione; un fake de test puede devolver un widget vacio.
  Widget get widget;
}
