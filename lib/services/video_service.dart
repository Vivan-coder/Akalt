import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';

class VideoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> uploadVideo({
    required File videoFile,
    required String userId,
    required String username,
    required String caption,
    required List<String> tags,
    required String restaurantId,
    required String restaurantName,
    required double price,
  }) async {
    try {
      final String videoId = _uuid.v4();
      final String path = 'videos/$userId/$videoId.mp4';
      final Reference ref = _storage.ref().child(path);

      // Upload video
      final UploadTask uploadTask = ref.putFile(videoFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Generate and upload thumbnail
      final String thumbnailUrl = await _generateAndUploadThumbnail(
        videoFile,
        videoId,
        userId,
      );

      // Create Video Model
      final VideoModel video = VideoModel(
        id: videoId,
        videoUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        dishName: caption,
        userId: userId,
        username: username,
        tags: tags,
        createdAt: DateTime.now(),
        price: price,
      );

      // Save to Firestore
      await _firestore.collection('videos').doc(videoId).set(video.toMap());

      // Initial feed score calculation
      await calculateAndSyncFeedScore(videoId);
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  /// Calculates and updates the feed score for a video
  Future<void> calculateAndSyncFeedScore(String videoId) async {
    try {
      final docSnapshot =
          await _firestore.collection('videos').doc(videoId).get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data();
      if (data == null) return;

      final video = VideoModel.fromMap(data);

      // Base Score: (likes * 2) + (saves * 5) + (orderClicks * 10)
      final double baseScore = (video.likes * 2.0) +
          (video.saves * 5.0) +
          (video.orderClicks * 10.0);

      // Time Decay: 10% penalty for every 24 hours since createdAt
      final hoursDiff = DateTime.now().difference(video.createdAt).inHours;
      // Decay factor = 0.9 ^ (hours / 24)
      final double decayFactor = pow(0.9, hoursDiff / 24.0).toDouble();

      final double finalScore = baseScore * decayFactor;

      await _firestore
          .collection('videos')
          .doc(videoId)
          .update({'feedScore': finalScore});
    } catch (e) {
      debugPrint('Error calculating feed score: $e');
    }
  }

  /// Generate video thumbnail and upload to Firebase Storage
  Future<String> _generateAndUploadThumbnail(
    File videoFile,
    String videoId,
    String userId,
  ) async {
    try {
      // Generate thumbnail from video at 1 second mark
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
        timeMs: 1000, // Extract frame at 1 second
      );

      if (thumbnailPath == null) {
        return ''; // Return empty string if thumbnail generation fails
      }

      // Upload thumbnail to Firebase Storage
      final String thumbPath = 'thumbnails/$userId/$videoId.jpg';
      final Reference thumbRef = _storage.ref().child(thumbPath);
      final File thumbnailFile = File(thumbnailPath);

      final UploadTask uploadTask = thumbRef.putFile(thumbnailFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up temporary thumbnail file
      await thumbnailFile.delete();

      return downloadUrl;
    } catch (e) {
      // Log error but don't fail video upload if thumbnail generation fails
      debugPrint('Failed to generate thumbnail: $e');
      return '';
    }
  }

  // Fetch all videos (ordered by creation date for now)
  Stream<List<VideoModel>> getVideos() {
    return _firestore
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VideoModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Fetch videos ordered by feed score
  Stream<List<VideoModel>> getFeedVideos() {
    return _firestore
        .collection('videos')
        .orderBy('feedScore', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VideoModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Fetch videos by user ID
  Stream<List<VideoModel>> getUserVideos(String userId) {
    return _firestore
        .collection('videos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VideoModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Toggle Like
  Future<void> toggleLike(String videoId, String userId) async {
    final videoRef = _firestore.collection('videos').doc(videoId);
    final likeRef = videoRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(videoRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(videoRef, {'likes': FieldValue.increment(1)});
      }
    });

    // Update score after like toggle
    await calculateAndSyncFeedScore(videoId);
  }

  // Toggle Save
  Future<void> toggleSave(String videoId, String userId) async {
    final videoRef = _firestore.collection('videos').doc(videoId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final savedVideos = List<String>.from(userDoc.data()?['savedVideos'] ?? []);

      if (savedVideos.contains(videoId)) {
        // Unsave
        transaction.update(userRef, {
          'savedVideos': FieldValue.arrayRemove([videoId]),
        });
        transaction.update(videoRef, {'saves': FieldValue.increment(-1)});
      } else {
        // Save
        transaction.update(userRef, {
          'savedVideos': FieldValue.arrayUnion([videoId]),
        });
        transaction.update(videoRef, {'saves': FieldValue.increment(1)});
      }
    });

    // Update score after save toggle
    await calculateAndSyncFeedScore(videoId);
  }

  // Check if video is liked by user
  Stream<bool> isLiked(String videoId, String userId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Add Comment
  Future<void> addComment(
    String videoId,
    String text,
    String userId,
    String username,
    String? photoUrl,
  ) async {
    final videoRef = _firestore.collection('videos').doc(videoId);
    final commentRef = videoRef.collection('comments').doc();

    final comment = CommentModel(
      id: commentRef.id,
      userId: userId,
      username: username,
      userPhotoUrl: photoUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(videoRef, {'comments': FieldValue.increment(1)});
    });
  }

  // Get Comments
  Stream<List<CommentModel>> getComments(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CommentModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Increment Share Count
  Future<void> incrementShareCount(String videoId) async {
    await _firestore.collection('videos').doc(videoId).update({
      'shares': FieldValue.increment(1),
    });
  }

  // Increment Order Click Count
  Future<void> incrementOrderClicks(String videoId, String restaurantId) async {
    // Increment on the video
    await _firestore.collection('videos').doc(videoId).update({
      'orderClicks': FieldValue.increment(1),
    });

    // Increment on the restaurant
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'totalOrderClicks': FieldValue.increment(1),
    });

    // Update score after order click
    await calculateAndSyncFeedScore(videoId);
  }

  // Log Engagement
  Future<void> logEngagement(String videoId, String type) async {
    try {
      // Get the video to find the restaurantId
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) return;
      final videoData = videoDoc.data();
      if (videoData == null) return;

      final restaurantId = videoData['restaurantId'];

      // Log the event to a global analytics collection
      await _firestore.collection('analytics').add({
        'videoId': videoId,
        'type': type, // 'view', 'like', 'order_click'
        'restaurantId': restaurantId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Handle specific counters
      if (type == 'view') {
        await _firestore.collection('videos').doc(videoId).update({
          'views': FieldValue.increment(1),
        });
      } else if (type == 'order_click') {
        // Already handled by incrementOrderClicks, but if this method is called independently
        // we might want to ensure we don't double count if the UI calls both.
        // Assuming the UI calls logEngagement INSTEAD of incrementOrderClicks for generic tracking,
        // or alongside it.
        // For now, let's assume 'order_click' here is just for the log stream,
        // and the actual counter increment happens in incrementOrderClicks.
        // However, the instructions say "Create logEngagement... Types should include 'view', 'like', 'order_click'".
        // It doesn't explicitly say "replace existing logic".
        // Safe to just log the event here.
      }
    } catch (e) {
      debugPrint('Error logging engagement: $e');
    }
  }
}
