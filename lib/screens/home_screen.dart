import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/plant_registration_form.dart';
import '../helpers/network_helper.dart';
import '../helpers/notification_helper.dart';
import '../helpers/sync_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  DateTime? _lastRefresh;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    final now = DateTime.now();

    // 너무 빈번한 새로고침 방지 (5초 간격)
    if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 5) {
      return;
    }

    _lastRefresh = now;

    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      if (NetworkHelper.isOnline) {
        if (plantProvider.hasPlant) {
          await plantProvider.loadPlantData();
        }

        // 백그라운드에서 동기화도 실행
        unawaited(SyncHelper.manualSync());

        NotificationHelper.showSuccessSnackBar(context, '데이터가 새로고침되었습니다.');
      } else {
        NotificationHelper.showOfflineSnackBar(context);
      }
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '새로고침에 실패했습니다: $e');
    }
  }

  Future<void> _retryConnection() async {
    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // 연결 상태 다시 확인
      final isConnected = await plantProvider.checkConnection();

      if (isConnected) {
        // 연결이 복구되면 데이터 다시 로드
        await plantProvider.loadPlantData();
        NotificationHelper.showSuccessSnackBar(context, '연결이 복구되었습니다.');
      } else {
        NotificationHelper.showErrorSnackBar(context, '서버에 연결할 수 없습니다.');
      }
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '연결 재시도에 실패했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 헤더
                _buildHeader(),
                SizedBox(height: 40),

                // 연결 상태 경고
                if (plantProvider.error != null)
                  _buildErrorWidget(plantProvider),

                // 오프라인 경고
                if (!NetworkHelper.isOnline)
                  _buildOfflineWidget(),

                SizedBox(height: 16),

                // 메인 컨텐츠
                plantProvider.hasPlant
                    ? _buildPlantInfoWidget(context, plantProvider)
                    : _buildNoPlantWidget(context, plantProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '스마트팜',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '가정용 식물 관리 시스템',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(PlantProvider plantProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                '연결 문제',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            plantProvider.error!,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: plantProvider.isLoading ? null : _retryConnection,
                icon: plantProvider.isLoading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.refresh, size: 16),
                label: Text(plantProvider.isLoading ? '재시도 중...' : '다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  plantProvider.clearError();
                },
                child: Text('무시'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange[700], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오프라인 모드',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '저장된 데이터를 표시하고 있습니다. 최신 정보는 인터넷 연결 후 확인하세요.',
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

  Widget _buildNoPlantWidget(BuildContext context, PlantProvider plantProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.eco_outlined,
              size: 50,
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 32),
          Text(
            '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxWidth: 280),
            child: Text(
              '첫 번째 식물을 등록하여 스마트팜을 시작해보세요. AI 인식 또는 수동 등록이 가능합니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: plantProvider.isLoading ? null : () {
              _showPlantRegistrationDialog(context);
            },
            icon: plantProvider.isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(Icons.add_circle_outline),
            label: Text(
              plantProvider.isLoading ? '처리 중...' : '식물 등록하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 24),

          // 추가 기능 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  _showFeaturesDialog(context);
                },
                icon: Icon(Icons.help_outline, size: 18),
                label: Text('기능 안내'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF666666),
                ),
              ),
              SizedBox(width: 16),
              TextButton.icon(
                onPressed: NetworkHelper.isOnline ? () async {
                  final plantProvider = Provider.of<PlantProvider>(context, listen: false);
                  await plantProvider.refreshPlantProfiles();

                  if (plantProvider.error == null) {
                    NotificationHelper.showSuccessSnackBar(context, '식물 데이터베이스가 업데이트되었습니다.');
                  }
                } : null,
                icon: Icon(Icons.cloud_download_outlined, size: 18),
                label: Text('DB 업데이트'),
                style: TextButton.styleFrom(
                  foregroundColor: NetworkHelper.isOnline ? Color(0xFF666666) : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfoWidget(BuildContext context, PlantProvider plantProvider) {
    final plant = plantProvider.plant!;
    final sensorData = plantProvider.sensorData;

    return Column(
      children: [
        // 식물 정보 카드
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            plant.species,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '등록일: ${plant.registeredDate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: plantProvider.getOverallStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        size: 32,
                        color: plantProvider.getOverallStatusColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // 센서 데이터 처리
        if (plantProvider.isLoading && sensorData == null)
          _buildLoadingWidget()
        else if (sensorData == null)
          _buildNoDataWidget(plantProvider)
        else
          _buildSensorDataWidget(plant, sensorData, plantProvider),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '센서 데이터를 불러오는 중...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(PlantProvider plantProvider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '센서 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 8),
            Text(
              NetworkHelper.isOnline
                  ? 'IoT 센서가 연결되어 있는지 확인해주세요'
                  : '오프라인 상태입니다. 연결 후 다시 시도해주세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: plantProvider.isLoading ? null : () async {
                await plantProvider.loadPlantData();
              },
              icon: Icon(Icons.refresh, size: 18),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataWidget(plant, sensorData, PlantProvider plantProvider) {
    return Column(
      children: [
        // 센서 데이터 그리드
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            SensorCard(
              icon: Icons.thermostat_outlined,
              color: Color(0xFFE57373),
              title: '온도',
              value: '${sensorData.temperature.toStringAsFixed(1)}°C',
              optimal: '최적: ${plant.optimalTempMin.toInt()}-${plant.optimalTempMax.toInt()}°C',
              isOptimal: plantProvider.isValueInRange(
                sensorData.temperature,
                plant.optimalTempMin,
                plant.optimalTempMax,
              ),
            ),
            SensorCard(
              icon: Icons.water_drop_outlined,
              color: Color(0xFF64B5F6),
              title: '습도',
              value: '${sensorData.humidity.toStringAsFixed(0)}%',
              optimal: '최적: ${plant.optimalHumidityMin.toInt()}-${plant.optimalHumidityMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.humidity,
                plant.optimalHumidityMin,
                plant.optimalHumidityMax,
              ),
            ),
            SensorCard(
              icon: Icons.opacity_outlined,
              color: Color(0xFF81C784),
              title: '토양 수분',
              value: '${sensorData.soilMoisture.toStringAsFixed(0)}%',
              optimal: '최적: ${plant.optimalSoilMoistureMin.toInt()}-${plant.optimalSoilMoistureMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.soilMoisture,
                plant.optimalSoilMoistureMin,
                plant.optimalSoilMoistureMax,
              ),
            ),
            SensorCard(
              icon: Icons.wb_sunny_outlined,
              color: Color(0xFFFFB74D),
              title: '조도',
              value: '${sensorData.light.toStringAsFixed(0)}%',
              optimal: '최적: ${plant.optimalLightMin.toInt()}-${plant.optimalLightMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.light,
                plant.optimalLightMin,
                plant.optimalLightMax,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // 상태 카드
        _buildStatusCard(plantProvider, sensorData),
      ],
    );
  }

  Widget _buildStatusCard(PlantProvider plantProvider, sensorData) {
    final overallStatus = plantProvider.getOverallStatus();
    final statusColor = plantProvider.getOverallStatusColor();

    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '식물 상태',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 상태',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        overallStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '마지막 업데이트',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  _formatLastUpdate(sensorData.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (overallStatus != '최적') ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusAdvice(overallStatus),
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastUpdate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getStatusAdvice(String status) {
    switch (status) {
      case '주의 필요':
        return '여러 환경 요소가 최적 범위를 벗어났습니다. 환경을 조정해주세요.';
      case '양호':
        return '대체로 좋은 상태입니다. 일부 환경 요소를 개선하면 더 좋을 것 같습니다.';
      default:
        return '식물이 건강한 상태입니다!';
    }
  }

  void _showPlantRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PlantRegistrationForm();
      },
    );
  }

  void _showFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('스마트팜 기능'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFeatureItem(Icons.sensors, '실시간 센서 모니터링', '온도, 습도, 토양수분, 조도를 실시간으로 확인'),
                _buildFeatureItem(Icons.camera_alt, 'AI 식물 인식', '카메라로 식물을 촬영하여 자동 식별 및 등록'),
                _buildFeatureItem(Icons.notifications, '스마트 알림', '최적 환경을 벗어날 때 즉시 알림'),
                _buildFeatureItem(Icons.trending_up, '성장 기록', '시간별, 일별 환경 데이터 트렌드 분석'),
                _buildFeatureItem(Icons.tune, '맞춤 설정', '식물별 최적 환경 범위 개인화'),
                _buildFeatureItem(Icons.cloud_sync, '클라우드 동기화', '데이터 백업 및 기기 간 동기화'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Color(0xFF4CAF50), size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}