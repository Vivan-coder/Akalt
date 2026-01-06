import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'restaurants';

  // Get all restaurants
  Stream<List<RestaurantModel>> getRestaurants() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantModel.fromMap(data);
      }).toList();
    });
  }

  // Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return RestaurantModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream restaurant by ID
  Stream<RestaurantModel?> streamRestaurantById(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return RestaurantModel.fromMap(data);
      }
      return null;
    });
  }

  // Create a restaurant (for seeding/admin)
  Future<void> createRestaurant(RestaurantModel restaurant) async {
    await _firestore
        .collection(_collection)
        .doc(restaurant.id)
        .set(restaurant.toMap());
  }

  // Search restaurants by name or cuisine
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();

    // Fetching a reasonable number of restaurants to filter client-side
    // as Firestore doesn't support native full-text search
    final allSnapshot = await _firestore
        .collection(_collection)
        .limit(50)
        .get();

    final results = allSnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return RestaurantModel.fromMap(data);
        })
        .where((restaurant) {
          final nameMatch = restaurant.name.toLowerCase().contains(queryLower);
          final cuisineMatch = restaurant.cuisine.toLowerCase().contains(
            queryLower,
          );
          return nameMatch || cuisineMatch;
        })
        .toList();

    return results;
  }

  // Get restaurants for map (fetch all for now as dataset is small)
  Future<List<RestaurantModel>> getAllRestaurants() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return RestaurantModel.fromMap(data);
    }).toList();
  }

  Future<void> seedRestaurants() async {
    final restaurants = [
      RestaurantModel(
        id: 'r1',
        name: 'Burger Boutique',
        cuisine: 'Burgers',
        rating: 4.5,
        imageUrl: 'https://via.placeholder.com/150',
        address: 'Manama',
        distance: 1.2,
        latitude: 26.2235,
        longitude: 50.5876,
        followersCount: 5000,
        totalOrderClicks: 1200,
      ),
      RestaurantModel(
        id: 'r2',
        name: 'Mirai',
        cuisine: 'Japanese',
        rating: 4.8,
        imageUrl: 'https://via.placeholder.com/150',
        address: 'Adliya',
        distance: 3.5,
        latitude: 26.2135,
        longitude: 50.5976,
        followersCount: 8000,
        totalOrderClicks: 3000,
      ),
      RestaurantModel(
        id: 'r3',
        name: 'Papa Kanafa',
        cuisine: 'Dessert',
        rating: 4.2,
        imageUrl: 'https://via.placeholder.com/150',
        address: 'Riffa',
        distance: 10.0,
        latitude: 26.1235,
        longitude: 50.5576,
        followersCount: 2000,
        totalOrderClicks: 500,
      ),
    ];

    for (var restaurant in restaurants) {
      await createRestaurant(restaurant);
    }
  }
}
