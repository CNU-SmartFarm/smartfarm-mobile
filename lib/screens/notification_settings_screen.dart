import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final BackgroundMonitoringService _backgroundService = BackgroundMonitoringService();

  bool _notificationsEnabled = true;
  bool _backgroundServiceEnabled = false;
  bool _autoStartEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 알림 설정 상태 불러오기
      _notificationsEnabled = await _notificationService.isNotificationEnabled();

      // 백그라운드 서비스 상태 불러오기
      _backgroundServiceEnabled = await _backgroundService.isServiceRunning();

      // 자동 시작 설정 불러오기
      _autoStartEnabled = await _backgroundService.getAutoStart();
    } catch (e) {
      print('설정 불러오기 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationSettings(),
            const SizedBox(height: 24),
            _buildBackgroundServiceSettings(),
            const SizedBox(height: 32),
            _buildTestNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알림 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('식물 상태 알림'),
              subtitle: const Text('식물이 적정 환경 범위를 벗어날 경우 알림을 받습니다'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                await _notificationService.setNotificationEnabled(value);
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '알림은 앱이 실행 중이거나 백그라운드 서비스가 활성화된 경우에만 작동합니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundServiceSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '백그라운드 서비스',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('백그라운드 모니터링'),
              subtitle: const Text('앱이 종료된 상태에서도 식물 상태를 모니터링합니다'),
              value: _backgroundServiceEnabled,
              onChanged: (value) async {
                setState(() {
                  _isLoading = true;
                });

                bool success = false;
                if (value) {
                  success = await _backgroundService.startService();
                } else {
                  success = await _backgroundService.stopService();
                }

                if (success) {
                  setState(() {
                    _backgroundServiceEnabled = value;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('백그라운드 서비스 상태 변경에 실패했습니다'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                setState(() {
                  _isLoading = false;
                });
              },
            ),
            SwitchListTile(
              title: const Text('부팅 시 자동 시작'),
              subtitle: const Text('기기 재시작 시 백그라운드 서비스를 자동으로 실행합니다'),
              value: _autoStartEnabled,
              onChanged: (value) async {
                await _backgroundService.setAutoStart(value);
                setState(() {
                  _autoStartEnabled = value;
                });
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '백그라운드 서비스는 배터리를 더 많이 소모할 수 있습니다. 절전 모드나 배터리 최적화 설정에서 이 앱을 제외해야 정상 작동합니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.notifications_active),
        label: const Text('테스트 알림 보내기'),
        onPressed: _notificationsEnabled ? _sendTestNotification : null,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.showPlantNotification(
      title: '테스트 알림',
      message: '식물 모니터링 알림이 정상적으로 작동 중입니다.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('테스트 알림이 전송되었습니다'),
      ),
    );
  }
}