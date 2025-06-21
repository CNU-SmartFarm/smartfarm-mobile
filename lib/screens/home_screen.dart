import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/plant_registration_form.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (plantProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (plantProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    plantProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => plantProvider.loadPlantData(),
                  child: Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 헤더
              _buildHeader(),
              SizedBox(height: 40),

              // 식물이 없을 때와 있을 때 분기
              plantProvider.hasPlant
                  ? _buildPlantInfoWidget(context, plantProvider)
                  : _buildNoPlantWidget(context, plantProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 40),
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

  Widget _buildNoPlantWidget(BuildContext context, PlantProvider plantProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.eco_outlined,
              size: 40,
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 24),
          Text(
            '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 식물을 등록해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: plantProvider.isLoading ? null : () {
              _showPlantRegistrationDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '식물 등록하기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfoWidget(BuildContext context, PlantProvider plantProvider) {
    final plant = plantProvider.plant!;
    final sensorData = plantProvider.sensorData;

    if (sensorData == null) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('센서 데이터를 불러오는 중...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 식물 정보 카드
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          plant.species,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        size: 28,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '등록일: ${plant.registeredDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '식물 상태',
              style: TextStyle(
                fontSize: 16,
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: plantProvider.getOverallStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    plantProvider.getOverallStatus(),
                    style: TextStyle(
                      color: plantProvider.getOverallStatusColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
                  '${sensorData.timestamp.hour.toString().padLeft(2, '0')}:${sensorData.timestamp.minute.toString().padLeft(2, '0')}:${sensorData.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}