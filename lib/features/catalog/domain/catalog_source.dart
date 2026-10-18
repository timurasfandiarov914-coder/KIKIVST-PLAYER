import '../../../core/models/catalog_track.dart';

abstract interface class CatalogSource {
  String get id;

  String get displayName;

  Future<List<CatalogTrack>> search(String query);
}
