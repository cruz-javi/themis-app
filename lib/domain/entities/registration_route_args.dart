class RegistrationRouteArgs {
  const RegistrationRouteArgs({
    required this.electionId,
    required this.assertion,
    required this.accountTag,
  });

  final String electionId;
  final String assertion;

  /// Etiqueta de la cuenta (hash local del `sub`, ver
  /// core/crypto/identity_seed.dart). Viaja la etiqueta y no el `sub` para que
  /// no se pueda volver a usar como seed de la identidad: sirve solo para
  /// detectar que el dispositivo cambio de votante.
  final String accountTag;
}
