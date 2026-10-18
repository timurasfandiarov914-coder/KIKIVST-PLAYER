enum CatalogProvider { soundCloud, spotify, youtubeMusic }

extension CatalogProviderLabel on CatalogProvider {
  String get label => switch (this) {
    CatalogProvider.soundCloud => 'SoundCloud',
    CatalogProvider.spotify => 'Spotify',
    CatalogProvider.youtubeMusic => 'YouTube Music',
  };
}

class CatalogTrack {
  const CatalogTrack({
    required this.id,
    required this.provider,
    required this.title,
    required this.artist,
    this.artworkUri,
    this.duration,
  });

  final String id;
  final CatalogProvider provider;
  final String title;
  final String artist;
  final Uri? artworkUri;
  final Duration? duration;

  String get cacheKey => '${provider.name}:$id';
}
