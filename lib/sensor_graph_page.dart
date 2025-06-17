import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorGraphPage extends StatelessWidget {
  final String sensorName;
  final List<double> values;

  const SensorGraphPage({Key? key, required this.sensorName, required this.values}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final current = values.last;
    final average = values.reduce((a, b) => a + b) / values.length;
    final Map<String, Map<String, dynamic>> sensorSettings = {
      '수분': {
        'unit': '%',
        'minY': 0.0,
        'maxY': 100.0,
        'recommended': '40~60%',
        'icon': Icons.opacity,
        'title': '수분',
      },
      '온도': {
        'unit': '°C',
        'minY': 0.0,
        'maxY': 50.0,
        'recommended': '20~25°C',
        'icon': Icons.thermostat,
        'title': '온도',
      },
      '습도': {
        'unit': '%',
        'minY': 0.0,
        'maxY': 100.0,
        'recommended': '50~70%',
        'icon': Icons.water,
        'title': '습도',
      },
      '조도': {
        'unit': '%',
        'minY': 0.0,
        'maxY': 100.0,
        'recommended': '60~80%',
        'icon': Icons.wb_sunny,
        'title': '조도',
      },
    };

    final setting = sensorSettings[sensorName] ?? {};
    final unit = setting['unit'] ?? '';
    final minY = setting['minY'] ?? 0.0;
    final maxY = setting['maxY'] ?? 100.0;
    final recommended = setting['recommended'] ?? '-';
    final title = setting['title'] ?? sensorName;
    final icon = setting['icon'] ?? Icons.sensors;

    return Scaffold(
      appBar: AppBar(
        title: Text('$title 변화 그래프'),
        backgroundColor: Colors.lightGreen.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    backgroundColor: Colors.white,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}', style: const TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < _timeLabels.length) {
                              return Text(_timeLabels[index], style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.green.shade400,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [Colors.green.withAlpha(100), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.green),
                      SizedBox(width: 8),
                      Text('$title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildInfoCard("현재 값", '${current.toStringAsFixed(1)}$unit'),
                  _buildInfoCard("평균 값", '${average.toStringAsFixed(1)}$unit'),
                  _buildInfoCard("권장 값", recommended),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<String> get _timeLabels {
    return ['13:00', '13:30', '14:00', '14:30', '15:00', '15:30'];
  }
}
