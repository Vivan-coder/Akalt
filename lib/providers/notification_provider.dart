import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider to manage initialization
final notificationProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final user = ref.watch(currentUserProvider);

  // Initialize listeners
  notificationService.initialize();

  // Request permission and save token when user logs in
  if (user != null) {
    notificationService.requestPermission().then((_) {
      notificationService.saveTokenToUser(user.uid);
    });
  }
});
