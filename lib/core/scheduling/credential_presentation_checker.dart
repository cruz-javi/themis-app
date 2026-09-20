import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/registration_repository.dart';
import '../storage/secure_identity_store.dart';

/// Chequeo oportunista (no background job real - ver
/// registration/README.md en themis-core, "limitación documentada
/// explícitamente"): si ya paso el delay aleatorio programado tras el
/// registro, presenta la credencial de forma anonima. Se llama al arrancar
/// la app y cada vez que vuelve a primer plano; si el usuario no vuelve a
/// abrir la app despues del delay, la credencial queda sin presentar hasta
/// que la abra.
Future<void> maybePresentPendingCredential({
  required SecureIdentityStore secureIdentityStore,
  required RegistrationRepository repository,
}) async {
  if (await secureIdentityStore.isPresentationDone()) {
    return;
  }

  final schedule = await secureIdentityStore.readPresentationSchedule();
  if (schedule == null) {
    debugPrint('[credential-presentation] no hay ningun schedule guardado');
    return;
  }
  final now = DateTime.now().toUtc();
  if (now.isBefore(schedule.presentAt)) {
    debugPrint(
      '[credential-presentation] todavia no toca - presentAt=${schedule.presentAt}, ahora=$now',
    );
    return;
  }

  final credential = await secureIdentityStore.readCredential();
  if (credential == null) {
    debugPrint('[credential-presentation] hay schedule pero no hay credencial guardada (raro)');
    return;
  }

  debugPrint('[credential-presentation] presentando credencial para electionId=${schedule.electionId}...');
  try {
    await repository.presentCredential(
      electionId: schedule.electionId,
      preparedMessage: credential.preparedMessage,
      signature: credential.signature,
    );
    await secureIdentityStore.markPresentationDone();
    debugPrint('[credential-presentation] presentada con exito');
  } on DioException catch (error) {
    final data = error.response?.data;
    final code = data is Map ? data['code'] as String? : null;
    debugPrint(
      '[credential-presentation] DioException: status=${error.response?.statusCode} code=$code message=${error.message}',
    );
    // Ya se habia presentado en un intento anterior que si llego a destino
    // (ej. la app se cerro antes de confirmar la respuesta) - el objetivo
    // ya esta cumplido, no es un error real.
    if (code == 'CREDENTIAL_ALREADY_PRESENTED') {
      await secureIdentityStore.markPresentationDone();
      return;
    }
    // Cualquier otro error (sin red, servidor caido, etc.) se deja para el
    // proximo chequeo oportunista - no hay usuario mirando la pantalla acá.
  } catch (error) {
    debugPrint('[credential-presentation] error inesperado: $error');
  }
}
