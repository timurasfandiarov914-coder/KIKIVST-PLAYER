import 'dart:async';

import '../../../core/models/catalog_track.dart';
import 'catalog_source.dart';

class SourceSearchFailure {
  const SourceSearchFailure({
    required this.sourceId,
    required this.message,
  });

  final String sourceId;
  final String message;
}

class SearchResponse {
  SearchResponse({
    required this.query,
    required List<CatalogTrack> tracks,
    required this.sourceCount,
    List<SourceSearchFailure> failures = const [],
  })  : tracks = List.unmodifiable(tracks),
        failures = List.unmodifiable(failures);

  final String query;
  final List<CatalogTrack> tracks;
  final int sourceCount;
  final List<SourceSearchFailure> failures;

  bool get hasFailures => failures.isNotEmpty;
}

class CatalogSearchService {
  CatalogSearchService({
    required List<CatalogSource> sources,
    this.sourceTimeout = const Duration(seconds: 7),
  }) : _sources = List.unmodifiable(sources);

  final List<CatalogSource> _sources;
  final Duration sourceTimeout;

  bool get hasSources => _sources.isNotEmpty;

  Future<SearchResponse> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty || _sources.isEmpty) {
      return SearchResponse(
        query: query,
        tracks: const [],
        sourceCount: _sources.length,
      );
    }

    final outcomes = await Future.wait(
      _sources.map((source) => _searchSource(source, query)),
    );

    final uniqueTracks = <String, CatalogTrack>{};
    final failures = <SourceSearchFailure>[];

    for (final outcome in outcomes) {
      final failure = outcome.failure;
      if (failure != null) failures.add(failure);
      for (final track in outcome.tracks) {
        uniqueTracks.putIfAbsent(track.cacheKey, () => track);
      }
    }

    return SearchResponse(
      query: query,
      tracks: uniqueTracks.values.toList(growable: false),
      sourceCount: _sources.length,
      failures: failures,
    );
  }

  Future<_SourceOutcome> _searchSource(
    CatalogSource source,
    String query,
  ) async {
    try {
      final tracks = await source.search(query).timeout(sourceTimeout);
      return _SourceOutcome(tracks: tracks);
    } on TimeoutException {
      return _SourceOutcome(
        tracks: const [],
        failure: SourceSearchFailure(
          sourceId: source.id,
          message: 'Search timed out.',
        ),
      );
    } catch (_) {
      return _SourceOutcome(
        tracks: const [],
        failure: SourceSearchFailure(
          sourceId: source.id,
          message: 'Source is temporarily unavailable.',
        ),
      );
    }
  }
}

class _SourceOutcome {
  const _SourceOutcome({
    required this.tracks,
    this.failure,
  });

  final List<CatalogTrack> tracks;
  final SourceSearchFailure? failure;
}
