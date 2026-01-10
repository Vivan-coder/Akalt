import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/restaurant_model.dart';
import '../models/video_model.dart';
import '../providers/restaurant_provider.dart';
import '../providers/video_provider.dart';

class GeoSearchService {
  final Ref _ref;

  GeoSearchService(this._ref);

  Future<List<VideoModel>> searchVideosNear(LatLng point, {double radiusKm = 2.0}) async {
    // 1. Get all restaurants (using the existing provider)
    final restaurants = await _ref.read(allRestaurantsProvider.future);

    // 2. Filter restaurants within radius
    final nearbyRestaurants = restaurants.where((restaurant) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        point,
        LatLng(restaurant.latitude, restaurant.longitude),
      );
      return distance <= radiusKm;
    }).toList();

    if (nearbyRestaurants.isEmpty) return [];

    // 3. Get videos for these restaurants
    // This is inefficient if we don't have a way to query videos by list of restaurant IDs.
    // Ideally: db.collection('videos').where('restaurantId', whereIn: ids).get()
    // For now, we will fetch all feed videos and filter.
    final allVideos = await _ref.read(homeVideosProvider.future);

    final restaurantIds = nearbyRestaurants.map((r) => r.id).toSet();

    return allVideos.where((video) => restaurantIds.contains(video.restaurantId)).toList();
  }
}

final geoSearchServiceProvider = Provider<GeoSearchService>((ref) {
  return GeoSearchService(ref);
});
