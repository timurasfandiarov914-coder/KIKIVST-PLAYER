import 'package:flutter_test/flutter_test.dart';
import 'package:kikivst_player/core/models/catalog_track.dart';
import 'package:kikivst_player/features/catalog/domain/catalog_search_service.dart';
import 'package:kikivst_player/features/catalog/domain/catalog_source.dart';

class _TestSource implements CatalogSource {
  _TestSource({required this.id, required this.result, this.error});

  @override
  final String id;

  final List<CatalogTrack> result;
  final Object? error;

  @override
  String get displayName => id;

  @override
  Future<List<CatalogTrack>> search(String query) async {
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  group('CatalogSearchService', () {
    test('does not query sources for an empty search', () async {
      final service = CatalogSearchService(
        sources: [_TestSource(id: 'source', result: const [])],
      );

      final response = await service.search('   ');

      expect(response.query, isEmpty);
      expect(response.tracks, isEmpty);
    });

    test('merges results from sources and trims the query', () async {
      final first = CatalogTrack(
        id: '1',
        provider: CatalogProvider.soundCloud,
        title: 'First',
        artist: 'Artist A',
      );
      final second = CatalogTrack(
        id: '2',
        provider: CatalogProvider.spotify,
        title: 'Second',
        artist: 'Artist B',
      );
      final service = CatalogSearchService(
        sources: [
          _TestSource(id: 'soundcloud', result: [first]),
          _TestSource(id: 'spotify', result: [second]),
        ],
      );

      final response = await service.search('  night drive  ');

      expect(response.query, 'night drive');
      expect(response.sourceCount, 2);
      expect(response.tracks.map((track) => track.title), ['First', 'Second']);
      expect(response.failures, isEmpty);
    });

    test('keeps successful results when another source fails', () async {
      final track = CatalogTrack(
        id: '1',
        provider: CatalogProvider.soundCloud,
        title: 'Playable result',
        artist: 'Artist',
      );
      final service = CatalogSearchService(
        sources: [
          _TestSource(id: 'working', result: [track]),
          _TestSource(
            id: 'broken',
            result: const [],
            error: StateError('offline'),
          ),
        ],
      );

      final response = await service.search('track');

      expect(response.tracks.single.title, 'Playable result');
      expect(response.failures, hasLength(1));
      expect(response.failures.single.sourceId, 'broken');
    });

    test('reports when no catalog adapters are configured', () async {
      final response = await CatalogSearchService(
        sources: const [],
      ).search('track');

      expect(response.sourceCount, 0);
      expect(response.tracks, isEmpty);
      expect(response.failures, isEmpty);
    });
  });
}
