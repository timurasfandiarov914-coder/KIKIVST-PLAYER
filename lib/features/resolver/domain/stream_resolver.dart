import '../../../core/models/catalog_track.dart';
import '../../../core/models/playable_track.dart';
import '../../../core/models/resolved_stream.dart';

abstract interface class TrackStreamResolver {
  String get sourceId;

  bool supports(CatalogTrack track);

  Future<ResolvedStream?> resolve(CatalogTrack track);
}

abstract interface class StreamResolver {
  Future<PlayableTrack?> resolve(CatalogTrack track);
}

class CompositeStreamResolver implements StreamResolver {
  CompositeStreamResolver({
    required List<TrackStreamResolver> resolvers,
  }) : _resolvers = List.unmodifiable(resolvers);

  final List<TrackStreamResolver> _resolvers;

  @override
  Future<PlayableTrack?> resolve(CatalogTrack track) async {
    for (final resolver in _resolvers) {
      if (!resolver.supports(track)) continue;

      final stream = await resolver.resolve(track);
      if (stream != null && !stream.isExpired()) {
        return PlayableTrack(track: track, stream: stream);
      }
    }

    return null;
  }
}
