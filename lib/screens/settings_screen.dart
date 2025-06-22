import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/plant_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/info_row.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        automaticallyImplyLeading: false,
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

                // 앱 정보 섹션
                SettingsSection(
                  title: '앱 정보',
                  child: _buildAppInfoSection(),
                ),

                SizedBox(height: 16),

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

  Widget _buildAppInfoSection() {
    return Column(
      children: [
        InfoRow(label: '앱 버전', value: '1.0.0'),
        InfoRow(label: '개발팀', value: '스마트팜 팀'),
        InfoRow(label: 'API 서버', value: 'api.smartfarm.com'),
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
                onPressed: () {
                  _showClearCacheDialog(context);
                },
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
}