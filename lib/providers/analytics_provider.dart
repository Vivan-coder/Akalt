import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';
import '../models/restaurant_model.dart';

class AnalyticsStats {
  final int totalViews;
  final int totalOrderClicks;

  AnalyticsStats({
    required this.totalViews,
    required this.totalOrderClicks,
  });
}

final restaurantAnalyticsProvider = FutureProvider.family<AnalyticsStats, String>((
  ref,
  restaurantId,
) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Get Total Order Clicks from Restaurant Model
  // This is more efficient than summing up all videos every time, assuming it's kept in sync.
  final restaurantDoc =
      await firestore.collection('restaurants').doc(restaurantId).get();
  int totalOrderClicks = 0;
  if (restaurantDoc.exists) {
    final restaurant = RestaurantModel.fromMap(restaurantDoc.data()!);
    totalOrderClicks = restaurant.totalOrderClicks;
  }

  // 2. Get Total Views by summing views from all videos of this restaurant
  // We have to query videos because we don't keep a running total on the restaurant model for views (yet).
  final videosSnapshot = await firestore
      .collection('videos')
      .where('restaurantId', isEqualTo: restaurantId)
      .get();

  int totalViews = 0;
  for (var doc in videosSnapshot.docs) {
    final video = VideoModel.fromMap(doc.data());
    totalViews += video.views;
  }

  return AnalyticsStats(
    totalViews: totalViews,
    totalOrderClicks: totalOrderClicks,
  );
});
