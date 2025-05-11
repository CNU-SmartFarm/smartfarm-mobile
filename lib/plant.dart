import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Plant extends StatefulWidget {
  const Plant({Key? key}) : super(key: key);

  @override
  State<Plant> createState() => _PlantState();
}

class _PlantState extends State<Plant> {
  double moisture = 40.0; //수분
  double light = 75.0;    //광량
  double temperature = 24.5; //온도
  double humidity = 55.0;    //습도

  @override
  Widget build(BuildContext context) {
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
                _buildSensorCard(Icons.water_drop, '수분', '$moisture%'),
                _buildSensorCard(Icons.wb_sunny, '빛', '$light%'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorCard(Icons.thermostat, '온도', '$temperature°C'),
                _buildSensorCard(Icons.water, '습도', '$humidity%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

//   Widget _buildCard({
//     required String title,
//     required String valueText,
//     required double value,
//     required Color color,
// }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 8),
//                   LinearProgressIndicator(
//                     value: value,
//                     color: color,
//                     backgroundColor: Colors.grey.shade300,
//                     minHeight: 10,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 16),
//             Text(
//               valueText,
//               style: const TextStyle(
//                 fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ],
//         ),
//       ),
//     );
//   }

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

  Widget _buildSensorCard(IconData icon, String label, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.grey.shade700),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(value,
              style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

