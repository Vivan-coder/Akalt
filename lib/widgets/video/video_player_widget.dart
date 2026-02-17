import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../theme/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../screens/profile/restaurant_profile_screen.dart';
import '../../providers/video_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comments_sheet.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/user_provider.dart';

// Local StateProvider for optimistic UI
final likeStateProvider = StateProvider.family<bool, String>((ref, videoId) {
  return false; // Initial state will be overridden by watching isLikedProvider
});

// Provider to check if a video is liked by the current user
final isLikedProvider = StreamProvider.family<bool, String>((ref, videoId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);

  return ref.watch(videoServiceProvider).isLiked(videoId, user.uid);
});

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final VideoModel video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isInitialized = true;
                  });
                  _controller.play();
                  _controller.setLooping(true);
                }
              })
              .catchError((error) {
                debugPrint('Video initialization error: $error');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error.toString();
                  });
                }
              });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like videos')),
      );
      return;
    }

    // Optimistic Update
    final isLiked = ref.read(likeStateProvider(widget.video.id));
    ref.read(likeStateProvider(widget.video.id).notifier).state = !isLiked;

    try {
      await ref
          .read(userServiceProvider)
          .toggleLike(widget.video.id, user.uid);
    } catch (e) {
      // Revert on error
      ref.read(likeStateProvider(widget.video.id).notifier).state = isLiked;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _launchOrderUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Track order click
      await ref.read(videoServiceProvider).incrementOrderClicks(
            widget.video.id,
            widget.video.restaurantId,
          );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLikedAsync = ref.watch(isLikedProvider(widget.video.id));

    // Watch restaurant data to determine if Order button should be shown
    final restaurantAsync = ref.watch(restaurantByIdProvider(widget.video.restaurantId));

    // Sync optimistic state with server state when it arrives
    ref.listen<AsyncValue<bool>>(isLikedProvider(widget.video.id), (previous, next) {
      next.whenData((liked) {
        ref.read(likeStateProvider(widget.video.id).notifier).state = liked;
      });
    });

    // Use local state for UI
    final isLiked = ref.watch(likeStateProvider(widget.video.id));

    return Stack(
      children: [
        // Video Player
        GestureDetector(
          onTap: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Video Error',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage ?? 'Unknown error',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.6, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Buttons (Foldable Safe)
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
              child: restaurantAsync.when(
                data: (restaurant) {
                  if (restaurant == null) return const SizedBox.shrink();

                  final buttons = <Widget>[];

                  // Order Now Button
                  if (widget.video.price > 0 &&
                      restaurant.orderLink != null &&
                      restaurant.orderLink!.isNotEmpty) {
                    buttons.add(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _launchOrderUrl(restaurant.orderLink!),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Order Now'),
                      ),
                    );
                  }

                  // WhatsApp Button
                  if (restaurant.referralLinks.containsKey('whatsapp') &&
                      restaurant.referralLinks['whatsapp']!.isNotEmpty) {
                    buttons.add(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _launchOrderUrl(restaurant.referralLinks['whatsapp']!),
                        icon: const Icon(Icons.chat), // Use a generic chat icon if Whatsapp not available
                        label: const Text('WhatsApp'),
                      ),
                    );
                  }

                  // Talabat Button
                  if (restaurant.referralLinks.containsKey('talabat') &&
                      restaurant.referralLinks['talabat']!.isNotEmpty) {
                    buttons.add(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _launchOrderUrl(restaurant.referralLinks['talabat']!),
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text('Talabat'),
                      ),
                    );
                  }

                  if (buttons.isEmpty) return const SizedBox.shrink();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: buttons,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Right Side Actions (Premium Look)
        Positioned(
          right: 16,
          bottom: 180, // Moved up to clear buttons
          child: Column(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
                backgroundColor: AppTheme.surfaceColor,
              ),
              const SizedBox(height: 24),
              _buildAction(
                context,
                isLiked ? Icons.favorite : Icons.favorite_border,
                '${widget.video.likes}',
                color: isLiked ? Colors.red : Colors.white,
                onTap: _handleLike,
              ),
              const SizedBox(height: 20),
              _buildAction(
                context,
                Icons.comment_rounded,
                '${widget.video.comments}',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        CommentsSheet(videoId: widget.video.id),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAction(
                context,
                Icons.share_rounded,
                'Share',
                onTap: () {
                  Share.share(
                    'Check out this delicious food! https://akalt.app/video/${widget.video.id}',
                  );
                  ref
                      .read(videoServiceProvider)
                      .incrementShareCount(widget.video.id);
                },
              ),
              // Removed old Order button
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 180, // Moved up to clear buttons
          right: 80,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantProfileScreen(
                    restaurant: RestaurantModel(
                      id: widget.video.restaurantId,
                      name: widget.video.restaurantName,
                      cuisine: 'Cuisine', // Placeholder
                      rating: 4.5, // Placeholder
                      imageUrl:
                          'https://via.placeholder.com/150', // Placeholder
                      address: 'Address', // Placeholder
                      distance: 1.2, // Placeholder
                      latitude: 0,
                      longitude: 0,
                      followersCount: 0,
                      totalOrderClicks: 0,
                    ),
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.video.restaurantName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    restaurantAsync.when(
                      data: (restaurant) =>
                          (restaurant != null && restaurant.isVerified)
                              ? const Icon(
                                  Icons.verified,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                )
                              : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.dishName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${widget.video.price.toStringAsFixed(3)} BHD',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String label, {
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
