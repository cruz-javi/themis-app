class BlindedMessage {
  const BlindedMessage({
    required this.blindedMessage,
    required this.preparedMessage,
    required this.inv,
  });

  /// Lo unico que se manda al backend (base64 de blindedMsg).
  final String blindedMessage;

  /// preparedMsg y inv se quedan en el dispositivo - hacen falta para
  /// descegar localmente la firma que devuelva el backend (suite.finalize).
  final String preparedMessage;
  final String inv;
}
