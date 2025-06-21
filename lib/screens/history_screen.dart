import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/plant_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/period_selector.dart';
import '../widgets/chart_legend.dart';
import '../helpers/network_helper.dart';
import '../helpers/notification_helper.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  bool _isRefreshing = false;
  DateTime? _lastRefresh;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    final now = DateTime.now();
    // 너무 빈번한 새로고침 방지 (3초 간격)
    if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 3) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _lastRefresh = now;
    });

    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      if (NetworkHelper.isOnline) {
        if (plantProvider.hasPlant) {
          await plantProvider.loadHistoricalData();
          NotificationHelper.showSuccessSnackBar(context, '데이터가 새로고침되었습니다.');
        }
      } else {
        // 오프라인에서도 로컬 데이터 새로고침
        await plantProvider.loadHistoricalData();
        NotificationHelper.showOfflineSnackBar(context);
      }
    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, '새로고침에 실패했습니다: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (!plantProvider.hasPlant) {
          return _buildNoPlantWidget();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '과거 데이터 조회',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // 연결 상태 경고
                if (plantProvider.error != null)
                  _buildErrorWidget(plantProvider),

                // 오프라인 모드 안내
                if (!NetworkHelper.isOnline)
                  _buildOfflineWidget(),

                // 기간 선택 카드
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '조회 기간',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isRefreshing)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        PeriodSelector(
                          selectedPeriod: plantProvider.selectedPeriod,
                          onPeriodChanged: (period) {
                            plantProvider.setSelectedPeriod(period);
                          },
                          isLoading: plantProvider.isLoading || _isRefreshing,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // 차트 카드
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '센서 데이터 변화',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                if (plantProvider.isLoading || _isRefreshing)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.refresh),
                                  onPressed: (plantProvider.isLoading || _isRefreshing)
                                      ? null
                                      : _refreshData,
                                  tooltip: '새로고침',
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 차트
                        Container(
                          height: 300,
                          child: _buildChart(context, plantProvider),
                        ),

                        SizedBox(height: 16),

                        // 범례
                        ChartLegend(),
                      ],
                    ),
                  ),
                ),

                // 데이터 요약 카드
                if (plantProvider.historicalData.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildDataSummaryCard(plantProvider),
                ],

                // 데이터 통계 카드
                if (plantProvider.historicalData.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildDataStatsCard(plantProvider),
                ],
              ],
            ),
          ),
        );
      },
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
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '데이터 로딩 오류',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  plantProvider.error!,
                  style: TextStyle(
                    color: Colors.red[700],
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '저장된 데이터를 표시하고 있습니다. 최신 데이터는 인터넷 연결 후 확인하세요.',
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

  Widget _buildNoPlantWidget() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 120),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 40,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 24),
          Text(
            '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxWidth: 280),
            child: Text(
              '홈 화면에서 식물을 등록하면 센서 데이터의 과거 기록을 확인할 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
              navigationProvider.goToHome();
            },
            icon: Icon(Icons.add_circle_outline),
            label: Text('식물 등록하러 가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, PlantProvider plantProvider) {
    if ((plantProvider.isLoading || _isRefreshing) && plantProvider.historicalData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (plantProvider.historicalData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '선택한 기간에 데이터가 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              NetworkHelper.isOnline
                  ? '다른 기간을 선택하거나 센서 연결을 확인해보세요'
                  : '온라인 상태에서 다시 시도해주세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('새로고침'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 &&
                    index < plantProvider.historicalData.length &&
                    index % _getDateInterval(plantProvider.historicalData.length) == 0) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateLabel(plantProvider.historicalData[index].date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // 온도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.temperature);
            }).toList(),
            isCurved: true,
            color: Colors.red[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 습도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.humidity);
            }).toList(),
            isCurved: true,
            color: Colors.blue[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 토양 수분 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.soilMoisture);
            }).toList(),
            isCurved: true,
            color: Colors.green[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 조도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.light);
            }).toList(),
            isCurved: true,
            color: Colors.orange[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard(PlantProvider plantProvider) {
    final data = plantProvider.historicalData;
    if (data.isEmpty) return SizedBox.shrink();

    // 평균값 계산
    final avgTemp = data.map((e) => e.temperature).reduce((a, b) => a + b) / data.length;
    final avgHumidity = data.map((e) => e.humidity).reduce((a, b) => a + b) / data.length;
    final avgSoil = data.map((e) => e.soilMoisture).reduce((a, b) => a + b) / data.length;
    final avgLight = data.map((e) => e.light).reduce((a, b) => a + b) / data.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '평균값 (${plantProvider.selectedPeriod})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.length}개 데이터',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '평균 온도',
                    '${avgTemp.toStringAsFixed(1)}°C',
                    Icons.thermostat_outlined,
                    Colors.red[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '평균 습도',
                    '${avgHumidity.toStringAsFixed(0)}%',
                    Icons.water_drop_outlined,
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '평균 토양수분',
                    '${avgSoil.toStringAsFixed(0)}%',
                    Icons.opacity_outlined,
                    Colors.green[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '평균 조도',
                    '${avgLight.toStringAsFixed(0)}%',
                    Icons.wb_sunny_outlined,
                    Colors.orange[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatsCard(PlantProvider plantProvider) {
    final data = plantProvider.historicalData;
    if (data.isEmpty) return SizedBox.shrink();

    // 최대/최소값 계산
    final maxTemp = data.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
    final minTemp = data.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
    final maxHumidity = data.map((e) => e.humidity).reduce((a, b) => a > b ? a : b);
    final minHumidity = data.map((e) => e.humidity).reduce((a, b) => a < b ? a : b);

    // 시간대별 분석
    final timeDistribution = <String, int>{};
    for (final point in data) {
      final hour = (point.time ~/ 100); // 시간 추출
      final timeRange = '${hour.toString().padLeft(2, '0')}:00';
      timeDistribution[timeRange] = (timeDistribution[timeRange] ?? 0) + 1;
    }

    final mostActiveTime = timeDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상세 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),

            // 온도 범위
            _buildStatRow('온도 범위', '${minTemp.toStringAsFixed(1)}°C ~ ${maxTemp.toStringAsFixed(1)}°C'),
            _buildStatRow('습도 범위', '${minHumidity.toStringAsFixed(0)}% ~ ${maxHumidity.toStringAsFixed(0)}%'),
            _buildStatRow('가장 활발한 시간', mostActiveTime),
            _buildStatRow('데이터 주기', _getDataFrequency(plantProvider.selectedPeriod)),

            if (!NetworkHelper.isOnline) ...[
              SizedBox(height: 8),
              Text(
                '* 오프라인 데이터 기준',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getDateInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 30) return 5;
    if (dataLength <= 100) return 10;
    return 20;
  }

  String _formatDateLabel(String date) {
    try {
      final DateTime dateTime = DateTime.parse(date);
      return '${dateTime.month}/${dateTime.day}';
    } catch (e) {
      return date;
    }
  }

  String _getDataFrequency(String period) {
    switch (period) {
      case '24h':
        return '10분 간격';
      case '7d':
        return '1시간 간격';
      case '30d':
        return '6시간 간격';
      case '90d':
        return '1일 간격';
      default:
        return '자동';
    }
  }
}