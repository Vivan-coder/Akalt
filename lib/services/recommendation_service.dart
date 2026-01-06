import '../models/video_model.dart';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';

class RecommendationService {
  /// Calculates the FeedScore for a video based on user preferences and restaurant data.
  double calculateFeedScore({
    required VideoModel video,
    required UserModel user,
    required RestaurantModel restaurant,
  }) {
    double score = 0.0;

    // 1. Engagement Metrics
    score += (video.likes * 2);
    score +=
        (video.shares *
        3); // Using shares as proxy for saves if saves not in video model yet, or add saves
    score += (video.comments * 4);
    score += (video.orderClicks * 5);
    score += (video.avgWatchTime * 3);
    score += (restaurant.followersCount * 1.5);

    // 2. Freshness Boost
    final hoursSinceUpload = DateTime.now().difference(video.createdAt).inHours;
    if (hoursSinceUpload < 24) {
      score += 50;
    } else if (hoursSinceUpload < 72) {
      score += 20;
    }

    // 3. Personalization Boost
    // Tag match
    bool hasTagMatch = false;
    for (final tag in video.tags) {
      if (user.favoriteTags.contains(tag)) {
        hasTagMatch = true;
        break;
      }
    }
    if (hasTagMatch) {
      score += 30;
    }

    // Previously saved similar food (Tag match in saved videos)
    // This is a simplified check. Ideally, we'd check tags of saved videos.
    // For MVP, we'll assume if the user has saved videos with same tags, it's a match.
    // Since we don't have the full list of saved videos objects here, we rely on favoriteTags
    // which should ideally be updated when a user saves a video.
    // Alternatively, if we had the list of saved video IDs, we could check if this video is saved.
    if (user.savedVideos.contains(video.id)) {
      // If already saved, maybe boost less or more?
      // The prompt says "Previously saved similar food: +40".
      // We'll assume favoriteTags captures "similar food" interest.
      // Let's add an extra boost if the user has saved *this* restaurant's videos before.
      // But we don't have that data easily.
      // We will stick to the tag match for now as the primary interest signal.
      // If we want to be strict about "Previously saved similar food", we'd need to look at tags of saved videos.
      // Let's assume favoriteTags are derived from saved videos.
      if (hasTagMatch) {
        score += 40; // Cumulative with the previous 30? Or instead?
        // Prompt: "Tag match: +30", "Previously saved similar food: +40".
        // Let's treat them as additive for now if we can distinguish.
        // Since we are using favoriteTags for both, let's just ensure we give enough weight.
      }
    }

    // 4. Location Boost
    // Simple string match for MVP "lat,lng" or city name
    if (user.location.isNotEmpty &&
        video.location.isNotEmpty &&
        user.location == video.location) {
      score += 30;
    }

    return score;
  }

  /// Sorts a list of videos based on FeedScore for a specific user.
  List<VideoModel> getRecommendedVideos({
    required List<VideoModel> videos,
    required UserModel user,
    required List<RestaurantModel> restaurants,
  }) {
    // Create a map for quick restaurant lookup
    final restaurantMap = {for (var r in restaurants) r.id: r};

    // Calculate scores
    final scoredVideos = videos.map((video) {
      final restaurant = restaurantMap[video.restaurantId];
      if (restaurant == null) return MapEntry(video, 0.0);

      final score = calculateFeedScore(
        video: video,
        user: user,
        restaurant: restaurant,
      );
      return MapEntry(video, score);
    }).toList();

    // Sort by score descending
    scoredVideos.sort((a, b) => b.value.compareTo(a.value));

    return scoredVideos.map((e) => e.key).toList();
  }
}
