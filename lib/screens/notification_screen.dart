import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/app_models.dart';
import '../widgets/notification_item_tile.dart';
import '../helpers/network_helper.dart';
import '../helpers/notification_helper.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with AutomaticKeepAliveClientMixin {
  bool _isRefreshing = false;
  DateTime? _lastRefresh;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshNotifications() async {
    if (_isRefreshing) return;

    final now = DateTime.now();
    // 너무 빈번한 새로고침 방지 (3초 간격)
    if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 3) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _lastRefresh = now;
    });

    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      if (NetworkHelper.isOnline) {
        if (plantProvider.hasPlant) {
          await plantProvider.loadPlantData();
          NotificationHelper.showSuccessSnackBar(context, '알림이 새로고침되었습니다.');
        }
      } else {
        NotificationHelper.showOfflineSnackBar(context);
      }
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '새로고침에 실패했습니다: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      final unreadNotifications = plantProvider.notifications
          .asMap()
          .entries
          .where((entry) => !entry.value.isRead)
          .toList();

      if (unreadNotifications.isEmpty) {
        NotificationHelper.showWarningSnackBar(context, '읽지 않은 알림이 없습니다.');
        return;
      }

      // 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('알림 읽음 처리'),
          content: Text('모든 알림을 읽음으로 처리하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('확인'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 모든 읽지 않은 알림을 읽음으로 처리
      for (final entry in unreadNotifications) {
        await plantProvider.markNotificationAsRead(entry.value.id, entry.key);
      }

      NotificationHelper.showSuccessSnackBar(context, '모든 알림이 읽음으로 처리되었습니다.');
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '처리 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<PlantProvider>(
            builder: (context, plantProvider, child) {
              if (plantProvider.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _refreshNotifications();
                        break;
                      case 'mark_all_read':
                        _markAllAsRead();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'refresh',
                      enabled: !_isRefreshing && NetworkHelper.isOnline,
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('새로고침'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'mark_all_read',
                      enabled: plantProvider.unreadNotificationsCount > 0,
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 20),
                          SizedBox(width: 8),
                          Text('모두 읽음'),
                        ],
                      ),
                    ),
                  ],
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

              // 오프라인 모드 안내
              if (!NetworkHelper.isOnline)
                _buildOfflineWarning(),

              // 알림 통계
              if (plantProvider.notifications.isNotEmpty)
                _buildNotificationStats(plantProvider),

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
          ElevatedButton(
            onPressed: settingsProvider.isLoading ? null : () async {
              final success = await settingsProvider.togglePushNotification();
              if (success) {
                NotificationHelper.showSuccessSnackBar(context, '푸시 알림이 활성화되었습니다.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연결 오류',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange[700],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오프라인 모드',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '저장된 알림을 표시하고 있습니다. 최신 알림은 인터넷 연결 후 확인하세요.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats(PlantProvider plantProvider) {
    final total = plantProvider.notifications.length;
    final unread = plantProvider.unreadNotificationsCount;
    final read = total - unread;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('전체', total, Colors.grey[600]!),
          ),
          Expanded(
            child: _buildStatItem('읽지 않음', unread, Colors.red[600]!),
          ),
          Expanded(
            child: _buildStatItem('읽음', read, Colors.green[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(
      BuildContext context,
      PlantProvider plantProvider,
      SettingsProvider settingsProvider,
      NavigationProvider navigationProvider,
      ) {
    if (_isRefreshing && plantProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('알림을 불러오는 중...'),
          ],
        ),
      );
    }

    if (plantProvider.notifications.isEmpty) {
      return _buildEmptyState(context, plantProvider, navigationProvider);
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: plantProvider.notifications.length + (_isRefreshing ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isRefreshing && index == plantProvider.notifications.length) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '새로고침 중...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 50,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 32),
          Text(
            plantProvider.hasPlant ? '새로운 알림이 없습니다' : '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxWidth: 280),
            child: Text(
              plantProvider.hasPlant
                  ? '센서 값이 최적 범위를 벗어나거나 중요한 이벤트가 발생하면 여기에 알림이 표시됩니다.'
                  : '홈 화면에서 식물을 등록하면 센서 모니터링과 함께 알림을 받을 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),

          if (!plantProvider.hasPlant) ...[
            ElevatedButton.icon(
              onPressed: () {
                // 홈 탭으로 이동
                navigationProvider.goToHome();
                NotificationHelper.showSuccessSnackBar(context, '홈 화면으로 이동했습니다.');
              },
              icon: Icon(Icons.add_circle_outline),
              label: Text('식물 등록하러 가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: NetworkHelper.isOnline && !_isRefreshing ? _refreshNotifications : null,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('새로고침'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    navigationProvider.goToHistory();
                  },
                  icon: Icon(Icons.trending_up, size: 18),
                  label: Text('데이터 보기'),
                ),
              ],
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
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 20),

              // 알림 메타 정보
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          _formatNotificationTime(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          notification.isRead ? '읽음' : '읽지 않음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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