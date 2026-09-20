/// Rango del delay aleatorio antes de presentar la credencial de forma
/// anonima (mitigacion parcial de correlacion por timing - ver
/// registration/README.md en themis-core, seccion "Presentacion anonima").
///
/// Valores chicos a proposito para poder probarlo en desarrollo sin esperar
/// horas. En un despliegue real este rango deberia ser de minutos a horas,
/// no de segundos - y lo ideal es reemplazar este delay por completo cuando
/// exista el Relayer (CU-10), en vez de llamar directo desde el dispositivo.
abstract final class CredentialPresentationConfig {
  static const minDelay = Duration.zero;
  static const maxDelay = Duration(milliseconds: 100);
}
