import 'package:flutter_test/flutter_test.dart';
import 'package:themis_app/core/crypto/prover_bridge.dart';

void main() {
  test('traduce el error de Semaphore cuando la identidad no esta en el arbol', () {
    final msg = friendlyProofError("The leaf at index '-1' does not exist in this tree");
    expect(msg, contains('todavía no está en el padrón'));
  });

  test('deja pasar los demas errores tal cual', () {
    expect(friendlyProofError('Tiempo agotado'), 'Tiempo agotado');
  });
}
