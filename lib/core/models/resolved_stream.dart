class ResolvedStream {
  ResolvedStream({
    required this.uri,
    this.expiresAt,
    Map<String, String> headers = const {},
  }) : headers = Map.unmodifiable(headers);

  final Uri uri;
  final DateTime? expiresAt;
  final Map<String, String> headers;

  bool isExpired([DateTime? now]) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(now ?? DateTime.now());
  }
}
