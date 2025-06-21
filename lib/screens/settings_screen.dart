import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/plant_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/info_row.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<PlantProvider, SettingsProvider>(
        builder: (context, plantProvider, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
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

                SizedBox(height: 32),

                // 위험 구역
                _buildDangerZone(context, plantProvider, settingsProvider),
              ],
            ),
          );
        },
      ),
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
              onChanged: settingsProvider.isLoading ? null : (value) {
                settingsProvider.togglePushNotification();
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
              onChanged: settingsProvider.isLoading ? null : (value) {
                if (value != null) {
                  settingsProvider.changeLanguage(value);
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
              onChanged: settingsProvider.isLoading ? null : (value) {
                if (value != null) {
                  settingsProvider.changeTheme(value);
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
        InfoRow(label: '개발팀', value: '돌보미 팀'),
        InfoRow(label: 'API 서버', value: 'api.smartfarm.com'),
        InfoRow(label: '마지막 동기화', value: _getLastSyncTime()),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('식물이 삭제되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(plantProvider.error ?? '식물 삭제에 실패했습니다.'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('설정이 초기화되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('설정 초기화에 실패했습니다.'),
                      backgroundColor: Colors.red,
                    ),
                  );
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

  String _getLastSyncTime() {
    // SyncHelper에서 마지막 동기화 시간을 가져오는 로직
    return '방금 전'; // 임시값
  }
}