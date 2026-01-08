import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/geo_search_service.dart';
import '../models/video_model.dart';
import '../models/restaurant_model.dart';

final geoSearchServiceProvider = Provider<GeoSearchService>((ref) {
  return GeoSearchService();
});

/// Parameter for geo-radius queries
class GeoQueryParams {
  final double latitude;
  final double longitude;
  final double radiusInKm;

  GeoQueryParams({
    required this.latitude,
    required this.longitude,
    this.radiusInKm = 2.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoQueryParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusInKm == other.radiusInKm;

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ radiusInKm.hashCode;
}

/// Provider for videos within a specific radius
final nearbyVideosProvider =
    StreamProvider.family<List<VideoModel>, GeoQueryParams>((ref, params) {
      return ref
          .watch(geoSearchServiceProvider)
          .getVideosWithinRadius(
            lat: params.latitude,
            lng: params.longitude,
            radiusInKm: params.radiusInKm,
          );
    });

/// Provider for restaurants within a specific radius
final nearbyRestaurantsProvider =
    StreamProvider.family<List<RestaurantModel>, GeoQueryParams>((ref, params) {
      return ref
          .watch(geoSearchServiceProvider)
          .getRestaurantsWithinRadius(
            lat: params.latitude,
            lng: params.longitude,
            radiusInKm: params.radiusInKm,
          );
    });
