class EnvironmentState {
  const EnvironmentState({
    required this.domain,
    required this.clientId,
    required this.redirectUri,
    required this.apiToken,
  });

  final String domain;
  final String clientId;
  final String redirectUri;
  final String apiToken;
}
