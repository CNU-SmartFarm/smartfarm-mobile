import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isLoading;

  const PeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'value': '24h', 'label': '지난 24시간'},
      {'value': '7d', 'label': '지난 7일'},
      {'value': '30d', 'label': '지난 30일'},
      {'value': '90d', 'label': '지난 90일'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: periods.map((period) {
        return _buildPeriodButton(
          period['value']!,
          period['label']!,
          context,
        );
      }).toList(),
    );
  }

  Widget _buildPeriodButton(String value, String label, BuildContext context) {
    bool isSelected = selectedPeriod == value;

    return ElevatedButton(
      onPressed: isLoading ? null : () {
        onPeriodChanged(value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor,
        foregroundColor: isSelected
            ? Colors.white
            : Theme.of(context).textTheme.bodyMedium?.color,
        elevation: isSelected ? 2 : 0,
        side: isSelected ? null : BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading && isSelected) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}