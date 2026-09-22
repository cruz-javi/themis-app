class RegistrationRouteArgs {
  const RegistrationRouteArgs({
    required this.electionId,
    required this.assertion,
  });

  final String electionId;
  final String assertion;
}
