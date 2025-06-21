import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String optimal;
  final bool isOptimal;

  const SensorCard({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.optimal,
    this.isOptimal = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isOptimal ? 1 : 2,
      color: isOptimal ? Colors.white : Color(0xFFFFF3E0),
      child: Container(
        decoration: isOptimal ? null : BoxDecoration(
          border: Border.all(color: Color(0xFFFFCC02), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOptimal ? Color(0xFF333333) : Color(0xFFE65100),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4),
              Flexible(
                child: Text(
                  optimal,
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isOptimal) ...[
                SizedBox(height: 4),
                Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFFF8F00),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}