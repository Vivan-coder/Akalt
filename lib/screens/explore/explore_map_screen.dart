import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant_model.dart';
import '../profile/restaurant_profile_screen.dart';
import '../../providers/restaurant_provider.dart';

class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  // Bahrain Center
  final LatLng _center = const LatLng(26.0667, 50.5577);

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // We need to access the current list of restaurants
    // Since we can't easily get the value from the provider synchronously here without watching,
    // we'll rely on the marker tap for navigation instead, which is more intuitive.
    // This tap handler can be used for general map interactions if needed.
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);

    return Scaffold(
      body: restaurantsAsync.when(
        data: (restaurants) {
          return FlutterMap(
            options: MapOptions(
              initialCenter: _center, // Bahrain
              initialZoom: 11.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.akalt.dev',
              ),
              MarkerLayer(
                markers: restaurants.map((restaurant) {
                  return Marker(
                    point: LatLng(restaurant.latitude, restaurant.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        _showRestaurantPreview(context, restaurant);
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showRestaurantPreview(
    BuildContext context,
    RestaurantModel restaurant,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(restaurant.imageUrl),
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          restaurant.cuisine,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Address: ${restaurant.address}'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RestaurantProfileScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  child: const Text('View Profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
