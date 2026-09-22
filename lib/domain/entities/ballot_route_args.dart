/// La pantalla de voto no necesita la assertion del SSO: mandarla junto con la
/// opcion votada ponia en la misma peticion quien vota y que vota. La prueba
/// zk-SNARK valida es la unica prueba de habilitacion que exige el backend.
class BallotRouteArgs {
  const BallotRouteArgs({required this.electionId});

  final String electionId;
}
