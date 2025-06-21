import 'package:flutter/material.dart';

import '../models/app_models.dart';

class NotificationItemTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationItemTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: notification.isRead
          ? Theme.of(context).cardColor
          : Theme.of(context).cardColor.withOpacity(0.95),
      elevation: notification.isRead ? 1 : 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.grey[500],
              ),
              SizedBox(width: 4),
              Text(
                _formatNotificationTime(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getNotificationColor(notification.type).withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _getNotificationTypeLabel(notification.type),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getNotificationColor(notification.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!notification.isRead) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 4),
            ],
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return Color(0xFFFF8F00);
      case 'error':
        return Color(0xFFE53E3E);
      case 'success':
        return Color(0xFF2E7D32);
      case 'info':
      default:
        return Color(0xFF2196F3);
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'warning':
        return '주의';
      case 'error':
        return '오류';
      case 'success':
        return '성공';
      case 'info':
      default:
        return '정보';
    }
  }

  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}