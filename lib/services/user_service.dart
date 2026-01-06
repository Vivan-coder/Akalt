import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
