import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/app_models.dart';
import '../widgets/notification_item_tile.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<PlantProvider>(
            builder: (context, plantProvider, child) {
              if (plantProvider.notifications.isNotEmpty) {
                return IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: plantProvider.isLoading ? null : () {
                    if (plantProvider.hasPlant) {
                      plantProvider.loadPlantData();
                    }
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer3<PlantProvider, SettingsProvider, NavigationProvider>(
        builder: (context, plantProvider, settingsProvider, navigationProvider, child) {
          return Column(
            children: [
              // 푸시 알림 상태 경고
              if (!settingsProvider.pushNotificationEnabled)
                _buildNotificationWarning(context, settingsProvider),

              // 네트워크 상태 경고
              if (plantProvider.error != null)
                _buildErrorWarning(plantProvider.error!),

              // 알림 목록
              Expanded(
                child: _buildNotificationsList(context, plantProvider, settingsProvider, navigationProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationWarning(BuildContext context, SettingsProvider settingsProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        border: Border.all(color: Color(0xFFFFCC02)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFFFF8F00),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '푸시 알림이 비활성화되어 있습니다',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '중요한 알림을 놓칠 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.togglePushNotification();
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFE65100),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: Text(
              '활성화',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWarning(String error) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      BuildContext context,
      PlantProvider plantProvider,
      SettingsProvider settingsProvider,
      NavigationProvider navigationProvider,
      ) {
    if (plantProvider.isLoading && plantProvider.notifications.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (plantProvider.notifications.isEmpty) {
      return _buildEmptyState(context, plantProvider, navigationProvider);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (plantProvider.hasPlant) {
          await plantProvider.loadPlantData();
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: plantProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = plantProvider.notifications[index];
          return NotificationItemTile(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                plantProvider.markNotificationAsRead(notification.id, index);
              }
              _showNotificationDetail(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PlantProvider plantProvider, NavigationProvider navigationProvider) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 40,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 24),
          Text(
            plantProvider.hasPlant ? '새로운 알림이 없습니다' : '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            plantProvider.hasPlant
                ? '센서 값이 최적 범위를 벗어나면 알림을 받을 수 있습니다'
                : '홈 화면에서 식물을 등록하면 알림을 받을 수 있습니다',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
          if (!plantProvider.hasPlant) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 홈 탭으로 이동
                navigationProvider.goToHome();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('홈 화면으로 이동했습니다.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('식물 등록하러 가기'),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, NotificationItem notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getNotificationTitle(notification.type),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatNotificationTime(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
            if (notification.type == 'warning' || notification.type == 'error')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // NavigationProvider를 사용해서 설정 화면으로 이동
                  Provider.of<NavigationProvider>(context, listen: false).goToSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: Text('설정 확인'),
              ),
          ],
        );
      },
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

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'warning':
        return '주의 알림';
      case 'error':
        return '오류 알림';
      case 'success':
        return '성공 알림';
      case 'info':
      default:
        return '정보 알림';
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