import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'video_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VideoService _videoService;

  UserService(this._videoService);

  // Toggle Follow
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    await _firestore.runTransaction((transaction) async {
      final currentUserDoc = await transaction.get(currentUserRef);
      final currentUserData = currentUserDoc.data();

      if (currentUserData == null) return;

      final following = List<String>.from(currentUserData['following'] ?? []);

      if (following.contains(targetUserId)) {
        // Unfollow
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Follow
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([currentUserId]),
        });
      }
    });
  }

  // Check if following
  Stream<bool> isFollowing(String currentUserId, String targetUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      doc,
    ) {
      final data = doc.data();
      if (data == null) return false;
      final following = List<String>.from(data['following'] ?? []);
      return following.contains(targetUserId);
    });
  }

  // Get User by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Stream User by ID
  Stream<UserModel?> streamUserById(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  // Toggle Like
  Future<void> toggleLike(String videoId, String userId) async {
    final videoRef = _firestore.collection('videos').doc(videoId);
    final likeRef = videoRef.collection('likes').doc(userId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(videoRef, {'likes': FieldValue.increment(-1)});
        transaction.update(userRef, {
          'likedVideos': FieldValue.arrayRemove([videoId]),
        });
      } else {
        // Like
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(videoRef, {'likes': FieldValue.increment(1)});
        transaction.update(userRef, {
          'likedVideos': FieldValue.arrayUnion([videoId]),
        });
      }
    });

    // Sync Score
    await _videoService.calculateAndSyncFeedScore(videoId);

    // Log Engagement
    await _videoService.logEngagement(videoId, 'like');
  }

  // Toggle Save
  Future<void> toggleSave(String videoId, String userId) async {
    final videoRef = _firestore.collection('videos').doc(videoId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final savedVideos = List<String>.from(
        userDoc.data()?['savedVideos'] ?? [],
      );

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

    // Sync Score
    await _videoService.calculateAndSyncFeedScore(videoId);
  }
}
