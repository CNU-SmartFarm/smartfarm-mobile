import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/plant_provider.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class PlantRegistrationForm extends StatefulWidget {
  @override
  _PlantRegistrationFormState createState() => _PlantRegistrationFormState();
}

class _PlantRegistrationFormState extends State<PlantRegistrationForm> {
  String _registrationMode = 'manual';
  String _plantName = '';
  String _plantSpecies = '';
  bool _isAIProcessing = false;
  Map<String, double> _optimalSettings = {
    'optimalTempMin': 18,
    'optimalTempMax': 25,
    'optimalHumidityMin': 40,
    'optimalHumidityMax': 70,
    'optimalSoilMoistureMin': 40,
    'optimalSoilMoistureMax': 70,
    'optimalLightMin': 60,
    'optimalLightMax': 90,
  };

  void _updateOptimalSettings(List<PlantProfile> plantProfiles) {
    PlantProfile? profile = plantProfiles.firstWhere(
          (p) => p.species == _plantSpecies,
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
        _optimalSettings = {
          'optimalTempMin': profile.optimalTempMin,
          'optimalTempMax': profile.optimalTempMax,
          'optimalHumidityMin': profile.optimalHumidityMin,
          'optimalHumidityMax': profile.optimalHumidityMax,
          'optimalSoilMoistureMin': profile.optimalSoilMoistureMin,
          'optimalSoilMoistureMax': profile.optimalSoilMoistureMax,
          'optimalLightMin': profile.optimalLightMin,
          'optimalLightMax': profile.optimalLightMax,
        };
      });
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_plantName.isEmpty || _plantSpecies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('식물 이름과 종류를 입력해주세요.')),
      );
      return;
    }

    Plant newPlant = Plant(
      id: '', // API에서 생성됨
      name: _plantName,
      species: _plantSpecies,
      registeredDate: DateTime.now().toString().split(' ')[0],
      optimalTempMin: _optimalSettings['optimalTempMin']!,
      optimalTempMax: _optimalSettings['optimalTempMax']!,
      optimalHumidityMin: _optimalSettings['optimalHumidityMin']!,
      optimalHumidityMax: _optimalSettings['optimalHumidityMax']!,
      optimalSoilMoistureMin: _optimalSettings['optimalSoilMoistureMin']!,
      optimalSoilMoistureMax: _optimalSettings['optimalSoilMoistureMax']!,
      optimalLightMin: _optimalSettings['optimalLightMin']!,
      optimalLightMax: _optimalSettings['optimalLightMax']!,
    );

    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    bool success = await plantProvider.registerPlant(newPlant);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('식물이 성공적으로 등록되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(plantProvider.error ?? '식물 등록에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAIRegistration(BuildContext context) async {
    setState(() {
      _isAIProcessing = true;
    });

    try {
      // 이미지 피커로 카메라 또는 갤러리에서 이미지 선택
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera, // 카메라 사용
        imageQuality: 80, // 이미지 품질 (1-100)
      );

      if (image == null) {
        setState(() {
          _isAIProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 선택해주세요.')),
        );
        return;
      }

      File imageFile = File(image.path);

      // PlantNet API 호출
      AIIdentificationResult? result = await ApiService.identifyPlant(imageFile);

      if (result == null) {
        throw Exception('식물을 인식할 수 없습니다.');
      }

      if (result.confidence < 0.3) {
        throw Exception('식물 인식 정확도가 낮습니다. (${(result.confidence * 100).toStringAsFixed(1)}%) 더 선명한 사진으로 다시 시도해주세요.');
      }

      // AI 인식 결과로 식물 등록
      Plant aiRecognizedPlant = Plant(
        id: '', // API에서 생성됨
        name: result.suggestedName,
        species: result.species,
        registeredDate: DateTime.now().toString().split(' ')[0],
        optimalTempMin: result.optimalSettings['optimalTempMin']!,
        optimalTempMax: result.optimalSettings['optimalTempMax']!,
        optimalHumidityMin: result.optimalSettings['optimalHumidityMin']!,
        optimalHumidityMax: result.optimalSettings['optimalHumidityMax']!,
        optimalSoilMoistureMin: result.optimalSettings['optimalSoilMoistureMin']!,
        optimalSoilMoistureMax: result.optimalSettings['optimalSoilMoistureMax']!,
        optimalLightMin: result.optimalSettings['optimalLightMin']!,
        optimalLightMax: result.optimalSettings['optimalLightMax']!,
      );

      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      bool success = await plantProvider.registerPlant(aiRecognizedPlant);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 인식으로 식물이 등록되었습니다!\n${result.species} (정확도: ${(result.confidence * 100).toStringAsFixed(1)}%)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(plantProvider.error ?? '식물 등록에 실패했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 인식 실패: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isAIProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '식물 등록',
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
                        // 등록 모드 선택
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isAIProcessing || plantProvider.isLoading) ? null : () {
                                  setState(() {
                                    _registrationMode = 'ai';
                                  });
                                },
                                icon: Icon(Icons.camera_alt_outlined, size: 18),
                                label: Text('AI 인식'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _registrationMode == 'ai' ? Color(0xFF4CAF50) : Color(0xFFF5F5F5),
                                  foregroundColor: _registrationMode == 'ai' ? Colors.white : Color(0xFF666666),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isAIProcessing || plantProvider.isLoading) ? null : () {
                                  setState(() {
                                    _registrationMode = 'manual';
                                  });
                                },
                                icon: Icon(Icons.add, size: 18),
                                label: Text('수동 등록'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _registrationMode == 'manual' ? Color(0xFF4CAF50) : Color(0xFFF5F5F5),
                                  foregroundColor: _registrationMode == 'manual' ? Colors.white : Color(0xFF666666),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        _registrationMode == 'ai'
                            ? _buildAIRegistration(context)
                            : _buildManualRegistration(context, plantProvider.plantProfiles),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIRegistration(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: _isAIProcessing
                ? CircularProgressIndicator()
                : Icon(
              Icons.photo_camera,
              size: 40,
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _isAIProcessing ? 'AI가 식물을 인식하는 중...' : 'AI 식물 인식',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _isAIProcessing
                ? '잠시만 기다려주세요'
                : '카메라 또는 갤러리에서 식물 사진을 선택하여 자동으로 등록하세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isAIProcessing ? null : () => _handleAIRegistration(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _isAIProcessing ? '인식 중...' : '사진으로 인식',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualRegistration(BuildContext context, List<PlantProfile> plantProfiles) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '식물 이름',
            hintText: '예: 내 몬스테라',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _plantName = value;
            });
          },
        ),

        SizedBox(height: 16),

        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: '식물 종류',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: _plantSpecies.isEmpty ? null : _plantSpecies,
          menuMaxHeight: 250,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down),
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
          ),
          onChanged: (String? value) {
            setState(() {
              _plantSpecies = value ?? '';
            });
            _updateOptimalSettings(plantProfiles);
          },
          selectedItemBuilder: (BuildContext context) {
            return [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '선택하세요',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...plantProfiles.map((PlantProfile profile) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${profile.species} (${profile.commonName})',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ];
          },
          items: [
            DropdownMenuItem(
              value: '',
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '선택하세요',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...plantProfiles.map((PlantProfile profile) {
              return DropdownMenuItem(
                value: profile.species,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.species,
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (profile.commonName.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          profile.commonName,
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),

        if (_plantSpecies.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildOptimalSettingsInfo(),
        ],

        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Consumer<PlantProvider>(
            builder: (context, plantProvider, child) {
              return ElevatedButton(
                onPressed: plantProvider.isLoading ? null : () => _handleSubmit(context),
                child: Text(
                  '식물 등록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalSettingsInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.green[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '자동 설정된 최적 환경',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptimalInfoRow(
                  Icons.thermostat_outlined,
                  '온도',
                  '${_optimalSettings['optimalTempMin']!.toInt()}°C - ${_optimalSettings['optimalTempMax']!.toInt()}°C',
                  Colors.red[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.water_drop_outlined,
                  '습도',
                  '${_optimalSettings['optimalHumidityMin']!.toInt()}% - ${_optimalSettings['optimalHumidityMax']!.toInt()}%',
                  Colors.blue[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.opacity_outlined,
                  '토양 수분',
                  '${_optimalSettings['optimalSoilMoistureMin']!.toInt()}% - ${_optimalSettings['optimalSoilMoistureMax']!.toInt()}%',
                  Colors.green[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.wb_sunny_outlined,
                  '조도',
                  '${_optimalSettings['optimalLightMin']!.toInt()}% - ${_optimalSettings['optimalLightMax']!.toInt()}%',
                  Colors.orange[400]!,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '💡 등록 후 설정에서 수정할 수 있습니다.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}