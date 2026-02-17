import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant_model.dart';
import '../../models/video_model.dart';
import '../../theme/app_theme.dart';
import '../explore/location_feed_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class RestaurantProfileScreen extends ConsumerWidget {
  final RestaurantModel restaurant;

  const RestaurantProfileScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock videos for this restaurant
    final List<VideoModel> restaurantVideos = List.generate(
      9,
      (index) => VideoModel(
        id: 'vid_${restaurant.id}_$index',
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        thumbnailUrl: 'https://via.placeholder.com/150',
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        dishName: 'Delicious Dish ${index + 1}',
        userId: 'user_rest_${restaurant.id}',
        username: restaurant.name,
        likes: (index + 1) * 150,
        comments: (index + 1) * 20,
        shares: (index + 1) * 5,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      ),
    );

    final isFollowingAsync = ref.watch(isFollowingProvider(restaurant.id));
    final isFollowing = isFollowingAsync.value ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(restaurant.name),
                  if (restaurant.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ],
                ],
              ),
              background: Image.network(
                restaurant.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.cuisine,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                restaurant.priceRange,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final currentUser = ref.read(currentUserProvider);
                          if (currentUser != null) {
                            await ref
                                .read(userServiceProvider)
                                .toggleFollow(currentUser.uid, restaurant.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? AppTheme.surfaceColor
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isFollowing ? 'Following' : 'Follow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Menu & Highlights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final video = restaurantVideos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationFeedScreen(
                        videos: restaurantVideos,
                        initialIndex: index,
                        title: restaurant.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.grey[300],
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.play_circle_outline),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 14,
                            ),
                            Text(
                              '${video.likes}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: restaurantVideos.length),
          ),
        ],
      ),
    );
  }
}
