import 'package:flutter_test/flutter_test.dart';
import 'package:themis_app/core/crypto/identity_seed.dart';

void main() {
  group('generateMnemonic', () {
    test('devuelve 12 palabras validas', () {
      final mnemonic = generateMnemonic();
      expect(mnemonic.split(' ').length, 12);
      expect(isValidMnemonic(mnemonic), isTrue);
    });

    // La propiedad central del cambio: la identidad ya no es funcion del
    // usuario. Antes se derivaba de 'themis:voter:<sub>', asi que el backend
    // (que conoce todos los sub) podia recalcular el nullifier de cada
    // votante y asociarlo con su voto.
    test('dos frases nuevas dan seeds sin relacion entre si', () {
      final seedA = seedFromMnemonic(generateMnemonic());
      final seedB = seedFromMnemonic(generateMnemonic());
      expect(seedA, isNot(seedB));
    });
  });

  group('accountTagFromSub', () {
    test('es estable para el mismo sub y distinto entre cuentas', () {
      expect(accountTagFromSub('user-a'), accountTagFromSub('user-a'));
      expect(accountTagFromSub('user-a'), isNot(accountTagFromSub('user-b')));
    });

    // La etiqueta solo indexa el storage: si se usara como seed volveria la
    // vulnerabilidad de derivar la identidad de un dato que el servidor conoce.
    test('no sirve para derivar la identidad', () {
      const sub = 'user-a';
      final tag = accountTagFromSub(sub);
      final mnemonicA = generateMnemonic();
      final mnemonicB = generateMnemonic();

      // Dos registros de la misma cuenta con frases distintas dan identidades
      // distintas: la cuenta no determina la identidad.
      expect(seedFromMnemonic(mnemonicA), isNot(seedFromMnemonic(mnemonicB)));
      expect(seedFromMnemonic(mnemonicA), isNot(contains(tag)));
    });
  });

  group('seedFromMnemonic', () {
    test('la misma frase da siempre el mismo seed (permite recuperar)', () {
      final mnemonic = generateMnemonic();
      expect(seedFromMnemonic(mnemonic), seedFromMnemonic(mnemonic));
    });

    test('tolera mayusculas y espacios extra del tipeo a mano', () {
      final mnemonic = generateMnemonic();
      final tipeada = '  ${mnemonic.toUpperCase().replaceAll(' ', '   ')}  ';
      expect(seedFromMnemonic(tipeada), seedFromMnemonic(mnemonic));
    });

    test('rechaza una frase invalida', () {
      expect(() => seedFromMnemonic('esto no es una frase bip39'), throwsArgumentError);
      expect(isValidMnemonic('esto no es una frase bip39'), isFalse);
      expect(isValidMnemonic(''), isFalse);
    });

    test('el seed es hex de 64 chars (sha256), apto como clave de Identity', () {
      final seed = seedFromMnemonic(generateMnemonic());
      expect(seed, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}
