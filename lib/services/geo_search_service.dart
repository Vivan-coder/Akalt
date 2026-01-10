import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/video_model.dart';
import '../models/restaurant_model.dart';

class GeoSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update video with geohash based on coordinates
  Future<void> updateVideoGeohash(
    String videoId,
    double lat,
    double lng,
  ) async {
    final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    await _firestore.collection('videos').doc(videoId).update({
      'geohash': geoFirePoint.geohash,
      'latitude': lat,
      'longitude': lng,
    });
  }

  /// Update restaurant with geohash based on coordinates
  Future<void> updateRestaurantGeohash(
    String restaurantId,
    double lat,
    double lng,
  ) async {
    final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'geohash': geoFirePoint.geohash,
      'latitude': lat,
      'longitude': lng,
    });
  }

  /// Query videos within a given radius in kilometers
  Stream<List<VideoModel>> getVideosWithinRadius({
    required double lat,
    required double lng,
    double radiusInKm = 2.0,
  }) {
    final center = GeoFirePoint(GeoPoint(lat, lng));
    final collectionReference = _firestore.collection('videos');

    return GeoCollectionReference(collectionReference)
        .subscribeWithin(
          center: center,
          radiusInKm: radiusInKm,
          field: 'geohash',
          geopointFrom: (data) {
            final lat = (data['latitude'] as num).toDouble();
            final lng = (data['longitude'] as num).toDouble();
            return GeoPoint(lat, lng);
          },
        )
        .map(
          (docs) => docs
              .map(
                (doc) =>
                    VideoModel.fromMap(doc.data()! as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Query restaurants within a given radius in kilometers
  Stream<List<RestaurantModel>> getRestaurantsWithinRadius({
    required double lat,
    required double lng,
    double radiusInKm = 2.0,
  }) {
    final center = GeoFirePoint(GeoPoint(lat, lng));
    final collectionReference = _firestore.collection('restaurants');

    return GeoCollectionReference(collectionReference)
        .subscribeWithin(
          center: center,
          radiusInKm: radiusInKm,
          field: 'geohash',
          geopointFrom: (data) {
            final lat = (data['latitude'] as num).toDouble();
            final lng = (data['longitude'] as num).toDouble();
            return GeoPoint(lat, lng);
          },
        )
        .map(
          (docs) => docs
              .map(
                (doc) => RestaurantModel.fromMap(
                  doc.data()! as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }
}