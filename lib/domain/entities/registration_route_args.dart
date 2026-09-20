class RegistrationRouteArgs {
  const RegistrationRouteArgs({
    required this.electionId,
    required this.assertion,
    this.sub,
  });

  final String electionId;
  final String assertion;
  final String? sub;
}
