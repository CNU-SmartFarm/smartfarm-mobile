import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../models/app_models.dart';

class PlantSettingsDialog extends StatefulWidget {
  @override
  _PlantSettingsDialogState createState() => _PlantSettingsDialogState();
}

class _PlantSettingsDialogState extends State<PlantSettingsDialog> {
  Map<String, double> _tempSettings = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initTempSettings();
  }

  void _initTempSettings() {
    final plant = Provider.of<PlantProvider>(context, listen: false).plant;
    if (plant != null) {
      _tempSettings = {
        'optimalTempMin': plant.optimalTempMin,
        'optimalTempMax': plant.optimalTempMax,
        'optimalHumidityMin': plant.optimalHumidityMin,
        'optimalHumidityMax': plant.optimalHumidityMax,
        'optimalSoilMoistureMin': plant.optimalSoilMoistureMin,
        'optimalSoilMoistureMax': plant.optimalSoilMoistureMax,
        'optimalLightMin': plant.optimalLightMin,
        'optimalLightMax': plant.optimalLightMax,
      };
    }
  }

  void _updateSetting(String key, double value) {
    setState(() {
      _tempSettings[key] = value;
      _hasChanges = true;
    });
  }

  void _resetToDefault() {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    final plant = plantProvider.plant;

    if (plant != null) {
      PlantProfile? profile = plantProvider.plantProfiles.firstWhere(
            (p) => p.species == plant.species,
        orElse: () => PlantProfile(
          species: '',
          commonName: '',
          optimalTempMin: 18,
          optimalTempMax: 25,
          optimalHumidityMin: 40,
          optimalHumidityMax: 70,
          optimalSoilMoistureMin: 40,
          optimalSoilMoistureMax: 70,
          optimalLightMin: 60,
          optimalLightMax: 90,
          description: '',
        ),
      );

      if (profile.species.isNotEmpty) {
        setState(() {
          _tempSettings = {
            'optimalTempMin': profile.optimalTempMin,
            'optimalTempMax': profile.optimalTempMax,
            'optimalHumidityMin': profile.optimalHumidityMin,
            'optimalHumidityMax': profile.optimalHumidityMax,
            'optimalSoilMoistureMin': profile.optimalSoilMoistureMin,
            'optimalSoilMoistureMax': profile.optimalSoilMoistureMax,
            'optimalLightMin': profile.optimalLightMin,
            'optimalLightMax': profile.optimalLightMax,
          };
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    final plant = plantProvider.plant;

    if (plant != null) {
      Plant updatedPlant = plant.copyWith(
        optimalTempMin: _tempSettings['optimalTempMin'],
        optimalTempMax: _tempSettings['optimalTempMax'],
        optimalHumidityMin: _tempSettings['optimalHumidityMin'],
        optimalHumidityMax: _tempSettings['optimalHumidityMax'],
        optimalSoilMoistureMin: _tempSettings['optimalSoilMoistureMin'],
        optimalSoilMoistureMax: _tempSettings['optimalSoilMoistureMax'],
        optimalLightMin: _tempSettings['optimalLightMin'],
        optimalLightMax: _tempSettings['optimalLightMax'],
      );

      bool success = await plantProvider.updatePlant(updatedPlant);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('최적 환경 설정이 업데이트되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(plantProvider.error ?? '설정 업데이트에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최적 환경 설정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: plantProvider.isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // 내용
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '각 센서의 최적 범위를 설정하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),

                        _buildSliderSection(
                          '온도 (°C)',
                          '${_tempSettings['optimalTempMin']!.toInt()}°C - ${_tempSettings['optimalTempMax']!.toInt()}°C',
                          10, 35,
                          _tempSettings['optimalTempMin']!,
                          _tempSettings['optimalTempMax']!,
                              (minVal, maxVal) {
                            _updateSetting('optimalTempMin', minVal);
                            _updateSetting('optimalTempMax', maxVal);
                          },
                          Icons.thermostat_outlined,
                          Colors.red[400]!,
                        ),

                        _buildSliderSection(
                          '습도 (%)',
                          '${_tempSettings['optimalHumidityMin']!.toInt()}% - ${_tempSettings['optimalHumidityMax']!.toInt()}%',
                          20, 90,
                          _tempSettings['optimalHumidityMin']!,
                          _tempSettings['optimalHumidityMax']!,
                              (minVal, maxVal) {
                            _updateSetting('optimalHumidityMin', minVal);
                            _updateSetting('optimalHumidityMax', maxVal);
                          },
                          Icons.water_drop_outlined,
                          Colors.blue[400]!,
                        ),

                        _buildSliderSection(
                          '토양 수분 (%)',
                          '${_tempSettings['optimalSoilMoistureMin']!.toInt()}% - ${_tempSettings['optimalSoilMoistureMax']!.toInt()}%',
                          10, 90,
                          _tempSettings['optimalSoilMoistureMin']!,
                          _tempSettings['optimalSoilMoistureMax']!,
                              (minVal, maxVal) {
                            _updateSetting('optimalSoilMoistureMin', minVal);
                            _updateSetting('optimalSoilMoistureMax', maxVal);
                          },
                          Icons.opacity_outlined,
                          Colors.green[400]!,
                        ),

                        _buildSliderSection(
                          '조도 (%)',
                          '${_tempSettings['optimalLightMin']!.toInt()}% - ${_tempSettings['optimalLightMax']!.toInt()}%',
                          30, 100,
                          _tempSettings['optimalLightMin']!,
                          _tempSettings['optimalLightMax']!,
                              (minVal, maxVal) {
                            _updateSetting('optimalLightMin', minVal);
                            _updateSetting('optimalLightMax', maxVal);
                          },
                          Icons.wb_sunny_outlined,
                          Colors.orange[400]!,
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 버튼들
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: plantProvider.isLoading ? null : () {
                          _resetToDefault();
                        },
                        child: Text('기본값 복원'),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: plantProvider.isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                        child: Text('취소'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (plantProvider.isLoading || !_hasChanges) ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: plantProvider.isLoading
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text('저장'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderSection(
      String title,
      String range,
      double min,
      double max,
      double minValue,
      double maxValue,
      Function(double, double) onChanged,
      IconData icon,
      Color color,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // 최소값 슬라이더
          Text(
            '최소값: ${minValue.toInt()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Slider(
            value: minValue,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: (value) {
              if (value < maxValue) {
                onChanged(value, maxValue);
              }
            },
          ),

          SizedBox(height: 8),

          // 최대값 슬라이더
          Text(
            '최대값: ${maxValue.toInt()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Slider(
            value: maxValue,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: (value) {
              if (value > minValue) {
                onChanged(minValue, value);
              }
            },
          ),
        ],
      ),
    );
  }
}