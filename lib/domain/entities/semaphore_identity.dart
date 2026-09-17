class SemaphoreIdentity {
  const SemaphoreIdentity({required this.privateKey, required this.commitment});

  /// Clave privada exportada por `@semaphore-protocol/identity` (`identity.export()`).
  /// Es el secreto a custodiar en `SecureIdentityStore` — nunca sale del dispositivo.
  final String privateKey;

  /// Identity commitment publico, derivado de la clave privada.
  final String commitment;
}
