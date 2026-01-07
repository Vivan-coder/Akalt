import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsData {
  final DateTime date;
  final int views;
  final int clicks;

  AnalyticsData({
    required this.date,
    required this.views,
    required this.clicks,
  });
}

class RestaurantAnalyticsNotifier extends StateNotifier<List<AnalyticsData>> {
  final String restaurantId;

  RestaurantAnalyticsNotifier(this.restaurantId) : super([]) {
    _loadMockData();
  }

  void _loadMockData() {
    final now = DateTime.now();
    final List<AnalyticsData> mockData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      // Generate some random numbers for mock data
      return AnalyticsData(
        date: date,
        views: 100 + (index * 20) + (date.day * 5),
        clicks: 10 + (index * 5) + (date.day),
      );
    });
    state = mockData;
  }

  Future<void> refreshAnalytics() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // In the future, this will fetch from Firestore
    _loadMockData();
  }
}

final restaurantAnalyticsProvider = StateNotifierProvider.family<
  RestaurantAnalyticsNotifier,
  List<AnalyticsData>,
  String
>((ref, restaurantId) {
  return RestaurantAnalyticsNotifier(restaurantId);
});
