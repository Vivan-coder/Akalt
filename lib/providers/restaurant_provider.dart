import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant_model.dart';
import 'auth_provider.dart';

final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  return RestaurantService();
});

final restaurantsProvider = StreamProvider<List<RestaurantModel>>((ref) {
  return ref.watch(restaurantServiceProvider).getRestaurants();
});

final restaurantByIdProvider = StreamProvider.family<RestaurantModel?, String>((
  ref,
  id,
) {
  return ref.watch(restaurantServiceProvider).streamRestaurantById(id);
});

final searchRestaurantsProvider =
    FutureProvider.family<List<RestaurantModel>, String>((ref, query) {
      return ref.watch(restaurantServiceProvider).searchRestaurants(query);
    });

final allRestaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) {
  return ref.watch(restaurantServiceProvider).getAllRestaurants();
});

final currentBusinessProvider = StreamProvider<RestaurantModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    return ref.watch(restaurantServiceProvider).streamRestaurantById(user.uid);
  }
  return Stream.value(null);
});
