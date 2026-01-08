import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.withValues(alpha: 0.1),
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  onTap: () {
                    ref
                        .read(notificationProvider.notifier)
                        .markAsRead(notification.id);
                  },
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead
                        ? Colors.grey[900]
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Icon(
                      _getIcon(notification.title),
                      color: notification.isRead
                          ? Colors.grey
                          : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.grey
                              : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: !notification.isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                );
              },
            ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Video')) return Icons.play_circle_outline;
    if (title.contains('Deal') || title.contains('%'))
      return Icons.local_offer_outlined;
    if (title.contains('Order')) return Icons.receipt_long_outlined;
    return Icons.notifications_none;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
