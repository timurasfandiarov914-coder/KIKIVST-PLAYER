import 'catalog_track.dart';
import 'resolved_stream.dart';

class PlayableTrack {
  const PlayableTrack({
    required this.track,
    required this.stream,
  });

  final CatalogTrack track;
  final ResolvedStream stream;
}
