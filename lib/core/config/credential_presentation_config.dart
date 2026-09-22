import 'env.dart';

/// Delay aleatorio antes de presentar la credencial de forma anonima
/// (segundo paso de CU-05, ver registration/README.md en themis-core).
///
/// **Para que sirve:** el registro va autenticado y queda en
/// `registration_requests` junto al `scoped_token_hash`, que identifica a la
/// persona. La presentacion es anonima y queda en `presented_credentials`
/// junto al `commitment`. Si ambas ocurren en el mismo instante, ordenar las
/// dos tablas por timestamp alcanza para asociar persona y commitment, y de
/// ahi -- via la prueba -- persona y voto. El delay rompe ese orden.
///
/// Es una mitigacion parcial, no una garantia criptografica: no oculta la IP
/// ni el momento del request. La mitigacion fuerte es el Relayer, pendiente.
/// El rango se configura en `assets/.env`
/// (`PRESENTATION_DELAY_MIN_SECONDS` / `PRESENTATION_DELAY_MAX_SECONDS`);
/// acortarlo para una demo reduce el conjunto de anonimato del lote.
abstract final class CredentialPresentationConfig {
  static Duration get minDelay => Env.presentationDelayMin;

  static Duration get maxDelay {
    final min = Env.presentationDelayMin;
    final max = Env.presentationDelayMax;
    return max < min ? min : max;
  }
}
