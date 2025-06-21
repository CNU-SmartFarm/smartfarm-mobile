import 'package:flutter/material.dart';

class ChartLegend extends StatelessWidget {
  const ChartLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(Colors.red[400]!, '온도 (°C)'),
        _buildLegendItem(Colors.blue[400]!, '습도 (%)'),
        _buildLegendItem(Colors.green[400]!, '토양 수분 (%)'),
        _buildLegendItem(Colors.orange[400]!, '조도 (%)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}