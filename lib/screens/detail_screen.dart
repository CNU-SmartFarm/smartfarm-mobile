import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/plant_provider.dart';
import '../models/plant.dart';
import '../models/plant_species.dart';
import '../models/sensor_data.dart';
import '../widgets/sensor_card.dart';
import '../widgets/chart_widget.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailScreen({
    required this.plantId,
    Key? key,
  }) : super(key: key);

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 표시되면 데이터 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false)
          .refreshPlantData(widget.plantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        // 식물 정보 찾기
        final plant = plantProvider.plants.firstWhere(
              (p) => p.id == widget.plantId,
          orElse: () => Plant(
            id: 'unknown',
            name: '알 수 없는 식물',
            speciesId: 'unknown',
          ),
        );

        // 식물 종 정보 찾기
        final species = plantProvider.getSpeciesById(plant.speciesId);

        return Scaffold(
          appBar: AppBar(
            title: Text(plant.name),
          ),
          body: RefreshIndicator(
            onRefresh: () => plantProvider.refreshPlantData(widget.plantId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 식물 정보 카드
                  _buildPlantInfoCard(plant, species),
                  const SizedBox(height: 24),

                  // 센서 데이터 카드
                  if (plant.latestData != null) ...[
                    _buildSensorDataSection(plant, species),
                    const SizedBox(height: 24),
                  ],

                  // 데이터 차트
                  if (plant.sensorHistory.isNotEmpty) ...[
                    _buildChartSection(plant),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('아직 수집된 센서 데이터가 없습니다'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 적정 환경 정보
                  if (species != null) ...[
                    _buildOptimalConditionsCard(species),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlantInfoCard(Plant plant, PlantSpecies? species) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 식물 아이콘/이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),

            // 식물 기본 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    species?.name ?? '알 수 없는 식물 종',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (plant.latestData != null) ...[
                    Text(
                      '마지막 업데이트: ${_formatDateTime(plant.latestData!.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataSection(Plant plant, PlantSpecies? species) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '현재 환경 상태',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SensorCard(
                icon: Icons.thermostat,
                title: '온도',
                value: '${plant.latestData!.temperature.toStringAsFixed(1)}°C',
                isInRange: species != null
                    ? species.temperatureRange.isInRange(plant.latestData!.temperature)
                    : true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SensorCard(
                icon: Icons.water_drop,
                title: '습도',
                value: '${plant.latestData!.humidity.toStringAsFixed(1)}%',
                isInRange: species != null
                    ? species.humidityRange.isInRange(plant.latestData!.humidity)
                    : true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SensorCard(
                icon: Icons.wb_sunny,
                title: '조도',
                value: '${plant.latestData!.light.toInt()} lux',
                isInRange: species != null
                    ? species.lightRange.isInRange(plant.latestData!.light)
                    : true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(Plant plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지난 24시간 데이터',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 온도 차트
        const Text(
          '온도 (°C)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ChartWidget(
            sensorHistory: plant.sensorHistory,
            valueType: SensorValueType.temperature,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),

        // 습도 차트
        const Text(
          '습도 (%)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ChartWidget(
            sensorHistory: plant.sensorHistory,
            valueType: SensorValueType.humidity,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),

        // 조도 차트
        const Text(
          '조도 (lux)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ChartWidget(
            sensorHistory: plant.sensorHistory,
            valueType: SensorValueType.light,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalConditionsCard(PlantSpecies species) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '적정 환경 조건',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEnvironmentConditionRow(
              Icons.thermostat,
              '온도',
              '${species.temperatureRange.min.toStringAsFixed(1)}-${species.temperatureRange.max.toStringAsFixed(1)}°C',
            ),
            _buildEnvironmentConditionRow(
              Icons.water_drop,
              '습도',
              '${species.humidityRange.min.toStringAsFixed(1)}-${species.humidityRange.max.toStringAsFixed(1)}%',
            ),
            _buildEnvironmentConditionRow(
              Icons.wb_sunny,
              '조도',
              '${species.lightRange.min.toInt()}-${species.lightRange.max.toInt()} lux',
            ),
            const SizedBox(height: 8),
            if (species.description.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(species.description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentConditionRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}