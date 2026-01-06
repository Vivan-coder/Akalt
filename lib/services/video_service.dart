import 'dart:io';
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
      );

      // Save to Firestore
      await _firestore.collection('videos').doc(videoId).set(video.toMap());
    } catch (e) {
      throw Exception('Failed to upload video: $e');
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
  }
}
