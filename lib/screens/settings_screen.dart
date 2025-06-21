import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/plant_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/info_row.dart';
import '../helpers/sync_helper.dart';
import '../helpers/network_helper.dart';
import '../helpers/notification_helper.dart';
import '../helpers/cache_helper.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  bool _isCheckingConnection = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _testConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isConnected = await ApiService.testConnection();

      if (isConnected) {
        NotificationHelper.showSuccessSnackBar(context, 'API 서버 연결이 정상입니다.');
      } else {
        NotificationHelper.showErrorSnackBar(context, 'API 서버에 연결할 수 없습니다.');
      }
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '연결 테스트 실패: $e');
    } finally {
      setState(() {
        _isCheckingConnection = false;
      });
    }
  }

  Future<void> _forceSyncData() async {
    if (!NetworkHelper.isOnline) {
      NotificationHelper.showErrorSnackBar(context, '인터넷 연결을 확인해주세요.');
      return;
    }

    try {
      await SyncHelper.forceSyncFromServer();

      // PlantProvider 데이터도 새로고침
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      if (plantProvider.hasPlant) {
        await plantProvider.loadPlantData();
      }

      NotificationHelper.showSuccessSnackBar(context, '데이터 동기화가 완료되었습니다.');
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '동기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: '도움말',
          ),
        ],
      ),
      body: Consumer2<PlantProvider, SettingsProvider>(
        builder: (context, plantProvider, settingsProvider, child) {
          if (settingsProvider.isLoading && settingsProvider.settings == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 연결 상태 섹션
                SettingsSection(
                  title: '연결 상태',
                  child: _buildConnectionSection(plantProvider, settingsProvider),
                ),

                SizedBox(height: 16),

                // 등록된 식물 섹션
                SettingsSection(
                  title: '등록된 식물',
                  child: _buildPlantSection(context, plantProvider),
                ),

                SizedBox(height: 16),

                // 식물 프로파일 섹션
                SettingsSection(
                  title: '식물 프로파일',
                  child: _buildPlantProfileSection(context, plantProvider),
                ),

                SizedBox(height: 16),

                // 알림 설정 섹션
                SettingsSection(
                  title: '알림 설정',
                  child: _buildNotificationSection(context, settingsProvider),
                ),

                SizedBox(height: 16),

                // 앱 설정 섹션
                SettingsSection(
                  title: '앱 설정',
                  child: _buildAppSection(context, settingsProvider),
                ),

                SizedBox(height: 16),

                // 데이터 관리 섹션
                SettingsSection(
                  title: '데이터 관리',
                  child: _buildDataManagementSection(context, plantProvider, settingsProvider),
                ),

                SizedBox(height: 16),

                // 앱 정보 섹션
                SettingsSection(
                  title: '앱 정보',
                  child: _buildAppInfoSection(plantProvider),
                ),

                SizedBox(height: 32),

                // 위험 구역
                _buildDangerZone(context, plantProvider, settingsProvider),

                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionSection(PlantProvider plantProvider, SettingsProvider settingsProvider) {
    return Column(
      children: [
        InfoRow(
          label: '네트워크 상태',
          value: NetworkHelper.isOnline ? '온라인' : '오프라인',
        ),
        InfoRow(
          label: 'API 서버',
          value: 'api.smartfarm.com',
        ),
        InfoRow(
          label: '동기화 상태',
          value: SyncHelper.isSyncing ? '동기화 중' : '대기',
        ),
        InfoRow(
          label: '마지막 동기화',
          value: _getLastSyncTime(),
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCheckingConnection ? null : _testConnection,
                icon: _isCheckingConnection
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.wifi_tethering),
                label: Text(_isCheckingConnection ? '확인 중...' : '연결 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (NetworkHelper.isOnline && !SyncHelper.isSyncing)
                    ? _forceSyncData
                    : null,
                icon: SyncHelper.isSyncing
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.sync),
                label: Text(SyncHelper.isSyncing ? '동기화 중...' : '강제 동기화'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        if (!NetworkHelper.isOnline) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '오프라인 모드에서는 저장된 데이터만 사용할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlantSection(BuildContext context, PlantProvider plantProvider) {
    if (!plantProvider.hasPlant) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 30,
                color: Color(0xFF999999),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '등록된 식물이 없습니다',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '홈 화면에서 식물을 등록해주세요',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final plant = plantProvider.plant!;
    return Column(
      children: [
        InfoRow(label: '식물 이름', value: plant.name),
        InfoRow(label: '종류', value: plant.species),
        InfoRow(label: '등록일', value: plant.registeredDate),
        InfoRow(label: '식물 ID', value: plant.id),

        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),

        Text(
          '현재 최적 환경 설정',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),

        _buildOptimalRangeInfo(
          Icons.thermostat_outlined,
          '온도',
          '${plant.optimalTempMin.toInt()}°C - ${plant.optimalTempMax.toInt()}°C',
          Colors.red[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.water_drop_outlined,
          '습도',
          '${plant.optimalHumidityMin.toInt()}% - ${plant.optimalHumidityMax.toInt()}%',
          Colors.blue[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.opacity_outlined,
          '토양 수분',
          '${plant.optimalSoilMoistureMin.toInt()}% - ${plant.optimalSoilMoistureMax.toInt()}%',
          Colors.green[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.wb_sunny_outlined,
          '조도',
          '${plant.optimalLightMin.toInt()}% - ${plant.optimalLightMax.toInt()}%',
          Colors.orange[400]!,
        ),

        SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: plantProvider.isLoading ? null : () {
              _showPlantSettingsDialog(context);
            },
            icon: Icon(Icons.tune),
            label: Text('최적 환경 수정'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantProfileSection(BuildContext context, PlantProvider plantProvider) {
    final cachedAge = plantProvider.getCachedProfilesAge();
    final isExpired = plantProvider.isCacheExpired();

    return Column(
      children: [
        InfoRow(
            label: '프로파일 개수',
            value: '${plantProvider.plantProfiles.length}개'
        ),
        if (cachedAge != null)
          InfoRow(
              label: '마지막 업데이트',
              value: _formatLastUpdate(cachedAge)
          ),
        InfoRow(
            label: '데이터 소스',
            value: NetworkHelper.isOnline ? 'API 서버' : '로컬 캐시'
        ),

        SizedBox(height: 16),

        if (isExpired && NetworkHelper.isOnline) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '식물 프로파일이 오래되었습니다. 새로고침을 권장합니다.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (plantProvider.isLoading || !NetworkHelper.isOnline) ? null : () async {
              await plantProvider.refreshPlantProfiles();

              if (plantProvider.error == null) {
                NotificationHelper.showSuccessSnackBar(context, '식물 프로파일이 업데이트되었습니다.');
              } else {
                NotificationHelper.showErrorSnackBar(context, plantProvider.error!);
              }
            },
            icon: plantProvider.isLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(Icons.refresh),
            label: Text(plantProvider.isLoading ? '업데이트 중...' : '프로파일 새로고침'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NetworkHelper.isOnline ? Color(0xFF4CAF50) : Colors.grey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        if (!NetworkHelper.isOnline) ...[
          SizedBox(height: 8),
          Text(
            '오프라인 상태에서는 새로고침할 수 없습니다.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '푸시 알림',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    settingsProvider.pushNotificationEnabled
                        ? '센서 값이 최적 범위를 벗어나면 알림을 받습니다'
                        : '알림이 비활성화되어 있습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settingsProvider.pushNotificationEnabled,
              onChanged: settingsProvider.isLoading ? null : (value) async {
                final success = await settingsProvider.togglePushNotification();
                if (success) {
                  NotificationHelper.showSuccessSnackBar(
                    context,
                    value ? '푸시 알림이 활성화되었습니다.' : '푸시 알림이 비활성화되었습니다.',
                  );
                }
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        if (settingsProvider.error != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              settingsProvider.error!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppSection(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '언어',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButton<String>(
              value: settingsProvider.language,
              underline: SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: settingsProvider.isLoading ? null : (value) async {
                if (value != null && value != settingsProvider.language) {
                  final success = await settingsProvider.changeLanguage(value);
                  if (success) {
                    NotificationHelper.showSuccessSnackBar(context, '언어가 변경되었습니다.');
                  }
                }
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '테마',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButton<String>(
              value: settingsProvider.theme,
              underline: SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'light', child: Text('밝은 모드')),
                DropdownMenuItem(value: 'dark', child: Text('어두운 모드')),
                DropdownMenuItem(value: 'system', child: Text('시스템 설정')),
              ],
              onChanged: settingsProvider.isLoading ? null : (value) async {
                if (value != null && value != settingsProvider.theme) {
                  final success = await settingsProvider.changeTheme(value);
                  if (success) {
                    NotificationHelper.showSuccessSnackBar(context, '테마가 변경되었습니다.');
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context, PlantProvider plantProvider, SettingsProvider settingsProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: NetworkHelper.isOnline ? () async {
              await _showSyncStatusDialog(context);
            } : null,
            icon: Icon(Icons.sync_alt),
            label: Text('동기화 상태'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDataExportDialog(context, settingsProvider),
            icon: Icon(Icons.download),
            label: Text('설정 내보내기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDataImportDialog(context, settingsProvider),
            icon: Icon(Icons.upload),
            label: Text('설정 가져오기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(PlantProvider plantProvider) {
    return Column(
      children: [
        InfoRow(label: '앱 버전', value: '1.0.0'),
        InfoRow(label: '개발팀', value: '돌보미 팀'),
        InfoRow(label: 'API 서버', value: 'http://43.201.68.168:8080'),
        InfoRow(label: '마지막 동기화', value: _getLastSyncTime()),
        InfoRow(label: '식물 DB 버전', value: _getPlantDBVersion(plantProvider)),
        InfoRow(label: '빌드 번호', value: '2024.06.22'),
      ],
    );
  }

  Widget _buildDangerZone(
      BuildContext context,
      PlantProvider plantProvider,
      SettingsProvider settingsProvider,
      ) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '위험 구역',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '아래 작업들은 되돌릴 수 없습니다. 신중하게 진행해주세요.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            if (plantProvider.hasPlant) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: plantProvider.isLoading ? null : () {
                    _showDeletePlantDialog(context, plantProvider);
                  },
                  icon: Icon(Icons.delete_outline),
                  label: Text('식물 삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: settingsProvider.isLoading ? null : () {
                  _showResetSettingsDialog(context, settingsProvider);
                },
                icon: Icon(Icons.restore),
                label: Text('설정 초기화'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: NetworkHelper.isOnline ? () {
                  _showClearCacheDialog(context);
                } : null,
                icon: Icon(Icons.clear_all),
                label: Text('캐시 초기화'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalRangeInfo(IconData icon, String label, String range, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          Spacer(),
          Text(
            range,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  String _getPlantDBVersion(PlantProvider plantProvider) {
    final cachedAge = plantProvider.getCachedProfilesAge();
    if (cachedAge != null) {
      return 'v${cachedAge.millisecondsSinceEpoch ~/ 1000000}';
    }
    return 'v1.0';
  }

  String _getLastSyncTime() {
    final lastSync = SyncHelper.getLastSyncTime();
    if (lastSync != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSync);

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
    return '알 수 없음';
  }

  // 다이얼로그들
  void _showPlantSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantSettingsDialog();
      },
    );
  }

  void _showDeletePlantDialog(BuildContext context, PlantProvider plantProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('식물 삭제'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정말로 식물을 삭제하시겠습니까?'),
              SizedBox(height: 8),
              Text(
                '삭제하면 다음 데이터가 모두 사라집니다:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text('• 식물 정보'),
              Text('• 센서 데이터 기록'),
              Text('• 알림 기록'),
              Text('• 설정 정보'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: plantProvider.isLoading ? null : () async {
                bool success = await plantProvider.deletePlant();
                Navigator.of(context).pop();

                if (success) {
                  NotificationHelper.showSuccessSnackBar(context, '식물이 삭제되었습니다.');
                } else {
                  NotificationHelper.showErrorSnackBar(context, plantProvider.error ?? '식물 삭제에 실패했습니다.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _showResetSettingsDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.restore, color: Colors.orange),
              SizedBox(width: 8),
              Text('설정 초기화'),
            ],
          ),
          content: Text('모든 앱 설정을 기본값으로 되돌리시겠습니까?\n(식물 데이터는 삭제되지 않습니다)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: settingsProvider.isLoading ? null : () async {
                bool success = await settingsProvider.resetSettings();
                Navigator.of(context).pop();

                if (success) {
                  NotificationHelper.showSuccessSnackBar(context, '설정이 초기화되었습니다.');
                } else {
                  NotificationHelper.showErrorSnackBar(context, '설정 초기화에 실패했습니다.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('초기화'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSyncStatusDialog(BuildContext context) async {
    final syncStatus = await SyncHelper.getSyncStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('동기화 상태'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('동기화되지 않은 데이터:'),
            SizedBox(height: 8),
            Text('• 식물: ${syncStatus['unSyncedPlantsCount']}개'),
            Text('• 센서 데이터: ${syncStatus['unSyncedSensorDataCount']}개'),
            Text('• 알림: ${syncStatus['unSyncedNotificationsCount']}개'),
            SizedBox(height: 12),
            Text('상태: ${syncStatus['isSyncing'] ? '동기화 중' : '대기 중'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog(BuildContext context, SettingsProvider settingsProvider) {
    final exportData = settingsProvider.exportSettings();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('설정 내보내기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('설정 데이터를 텍스트로 복사할 수 있습니다.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                exportData?.toString() ?? '설정 데이터 없음',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDataImportDialog(BuildContext context, SettingsProvider settingsProvider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('설정 가져오기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('내보낸 설정 데이터를 붙여넣기하세요.'),
            SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: '설정 데이터 붙여넣기',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 간단한 JSON 파싱 시뮬레이션
                NotificationHelper.showSuccessSnackBar(context, '설정 가져오기는 아직 구현되지 않았습니다.');
                Navigator.of(context).pop();
              } catch (e) {
                NotificationHelper.showErrorSnackBar(context, '올바른 설정 데이터가 아닙니다.');
              }
            },
            child: Text('가져오기'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.clear_all, color: Colors.orange),
            SizedBox(width: 8),
            Text('캐시 초기화'),
          ],
        ),
        content: Text('모든 캐시 데이터를 삭제하시겠습니까?\n앱이 다시 시작되고 데이터를 새로 로드합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await CacheHelper.clear();
                Navigator.of(context).pop();
                NotificationHelper.showSuccessSnackBar(context, '캐시가 초기화되었습니다. 앱을 재시작해주세요.');
              } catch (e) {
                NotificationHelper.showErrorSnackBar(context, '캐시 초기화에 실패했습니다.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('초기화'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('설정 도움말'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('연결 테스트', 'API 서버와의 연결 상태를 확인합니다.'),
              _buildHelpItem('강제 동기화', '서버에서 최신 데이터를 강제로 가져옵니다.'),
              _buildHelpItem('프로파일 새로고침', '식물 프로파일 데이터를 업데이트합니다.'),
              _buildHelpItem('동기화 상태', '로컬과 서버 간 동기화 상태를 확인합니다.'),
              _buildHelpItem('오프라인 모드', '인터넷 없이도 저장된 데이터를 사용할 수 있습니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}