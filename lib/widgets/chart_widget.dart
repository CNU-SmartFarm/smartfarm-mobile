import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';

enum SensorValueType {
  temperature,
  humidity,
  light,
}

class ChartWidget extends StatelessWidget {
  final List<SensorData> sensorHistory;
  final SensorValueType valueType;
  final Color color;

  const ChartWidget({
    required this.sensorHistory,
    required this.valueType,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sensorHistory.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다'),
      );
    }

    // 시간순으로 정렬된 데이터
    final sortedData = List<SensorData>.from(sensorHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= sortedData.length) {
                  return const SizedBox.shrink();
                }
                // 2시간 간격으로 시간 표시
                if (value.toInt() % 8 != 0 && value.toInt() != sortedData.length - 1) {
                  return const SizedBox.shrink();
                }

                final dateTime = sortedData[value.toInt()].timestamp;
                return Text(
                  '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(valueType == SensorValueType.light ? 0 : 1),
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: sortedData.length - 1.0,
        minY: _getMinY(),
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(sortedData),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index < 0 || index >= sortedData.length) {
                  return null;
                }

                final data = sortedData[index];
                final value = _getValue(data);
                final dateTime = data.timestamp;

                return LineTooltipItem(
                  '${_formatDateTime(dateTime)}\n$value${_getUnit()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(List<SensorData> data) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), _getValue(data[i])));
    }
    return spots;
  }

  double _getValue(SensorData data) {
    switch (valueType) {
      case SensorValueType.temperature:
        return data.temperature;
      case SensorValueType.humidity:
        return data.humidity;
      case SensorValueType.light:
        return data.light;
    }
  }

  String _getUnit() {
    switch (valueType) {
      case SensorValueType.temperature:
        return '°C';
      case SensorValueType.humidity:
        return '%';
      case SensorValueType.light:
        return ' lux';
    }
  }

  double _getMinY() {
    if (sensorHistory.isEmpty) return 0;

    double min = _getValue(sensorHistory.first);
    for (final data in sensorHistory) {
      final value = _getValue(data);
      if (value < min) min = value;
    }

    // 여유 공간 추가
    return min - (valueType == SensorValueType.light ? 100 : 2);
  }

  double _getMaxY() {
    if (sensorHistory.isEmpty) return 100;

    double max = _getValue(sensorHistory.first);
    for (final data in sensorHistory) {
      final value = _getValue(data);
      if (value > max) max = value;
    }

    // 여유 공간 추가
    return max + (valueType == SensorValueType.light ? 100 : 2);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}