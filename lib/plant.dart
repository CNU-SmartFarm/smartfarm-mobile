import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smartfarm/sensor_graph_page.dart';

class Plant extends StatefulWidget {
  const Plant({Key? key}) : super(key: key);

  @override
  State<Plant> createState() => _PlantState();
}

class _PlantState extends State<Plant> {
  final Map<String, bool> _isPressed = {};

  @override
  Widget build(BuildContext context) {
    final List<double> moistureValues = [30, 32, 34, 36, 38, 40];
    final List<double> lightValues = [70, 72, 74, 76, 78, 80];
    final List<double> temperatureValues = [22, 23, 24, 24.5, 25, 25.5];
    final List<double> humidityValues = [50, 52, 54, 55, 56, 58];

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.lightGreen.shade200,
          title: Text('내 식물 친구',
              style: TextStyle(color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Galmuri',
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.lightGreen.shade600,
                      offset: const Offset(2, 2),
                    )
                  ]
              )
          )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPlantStatus(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorCard(Icons.water_drop, '수분', '${moistureValues.last}%', moistureValues, Colors.blue),
                _buildSensorCard(Icons.wb_sunny, '조도', '${lightValues.last}%', lightValues, Colors.amber),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorCard(Icons.thermostat, '온도', '${temperatureValues.last}°C', temperatureValues, Colors.redAccent),
                _buildSensorCard(Icons.water, '습도', '${humidityValues.last}%', humidityValues, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Lottie.asset(
            'assets/Animation.json',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(IconData icon, String label, String value, List<double> values, Color iconColor) {
    final isPressed = _isPressed[label] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed[label] = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed[label] = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorGraphPage(
                sensorName: label,
                values: values,
            ),
          ),
        );
      },
      onTapCancel: () {
        setState(() => _isPressed[label] = false);
      },
      child: AnimatedScale(
          scale: isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 30, color: iconColor),
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontSize: 14)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

