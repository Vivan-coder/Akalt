import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant_model.dart';
import '../profile/restaurant_profile_screen.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/geo_search_service.dart';
import '../../widgets/video/video_feed.dart';
import 'location_feed_screen.dart';

class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  // Bahrain Center
  final LatLng _center = const LatLng(26.0667, 50.5577);
  bool _isLoading = false;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Standard tap logic
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _isLoading = true;
    });

    final geoService = ref.read(geoSearchServiceProvider);

    final videos = await geoService.searchVideosNear(point);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No videos found within 2km')),
      );
      return;
    }

    // Show horizontal list of videos in BottomSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nearby Eats (${videos.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16, bottom: 32),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to full feed starting at this video
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationFeedScreen(
                                videos: videos,
                                initialIndex: index,
                                title: 'Nearby Videos',
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                video.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.restaurantName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      video.dishName,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);

    return Scaffold(
      body: restaurantsAsync.when(
        data: (restaurants) {
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center, // Bahrain
                  initialZoom: 11.0,
                  onTap: _onMapTap,
                  onLongPress: _onMapLongPress,
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
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
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
