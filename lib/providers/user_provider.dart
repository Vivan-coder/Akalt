import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Stream to check if current user is following target user
final isFollowingProvider = StreamProvider.family<bool, String>((
  ref,
  targetUserId,
) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(false);
  return ref
      .watch(userServiceProvider)
      .isFollowing(currentUser.uid, targetUserId);
});

// Stream user by ID
final userByIdProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return ref.watch(userServiceProvider).streamUserById(userId);
});
