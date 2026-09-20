class BallotRouteArgs {
  const BallotRouteArgs({
    required this.electionId,
    this.assertion,
  });

  final String electionId;
  final String? assertion;
}
