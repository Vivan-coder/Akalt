import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/video_service.dart';
import '../models/video_model.dart';

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

// Provider for all videos in the home feed
final homeVideosProvider = StreamProvider<List<VideoModel>>((ref) {
  return ref.watch(videoServiceProvider).getFeedVideos();
});

// Provider for videos related to a specific user (or business)
final userVideosProvider = StreamProvider.family<List<VideoModel>, String>((
  ref,
  userId,
) {
  return ref.watch(videoServiceProvider).getUserVideos(userId);
});
