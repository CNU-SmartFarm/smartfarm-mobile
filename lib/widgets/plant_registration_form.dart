import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/plant_provider.dart';
import '../models/app_models.dart';
import '../helpers/permission_helper.dart';
import '../helpers/notification_helper.dart';

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
      NotificationHelper.showErrorSnackBar(context, '식물 이름과 종류를 입력해주세요.');
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
      NotificationHelper.showSuccessSnackBar(context, '식물이 성공적으로 등록되었습니다.');
    } else {
      NotificationHelper.showErrorSnackBar(context, plantProvider.error ?? '식물 등록에 실패했습니다.');
    }
  }

  Future<void> _handleAIRegistration(BuildContext context) async {
    setState(() {
      _isAIProcessing = true;
    });

    try {
      // 카메라 권한 확인
      final hasPermission = await PermissionHelper.checkCameraPermission();
      if (!hasPermission) {
        final granted = await PermissionHelper.requestCameraPermission();
        if (!granted) {
          NotificationHelper.showErrorSnackBar(context, '카메라 권한이 필요합니다.');
          return;
        }
      }

      // 이미지 소스 선택 다이얼로그
      final imageSource = await _showImageSourceDialog(context);
      if (imageSource == null) return;

      // 이미지 피커로 이미지 선택
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: imageSource,
        imageQuality: 85, // 이미지 품질 (1-100)
        maxWidth: 1024,   // 최대 너비
        maxHeight: 1024,  // 최대 높이
      );

      if (image == null) {
        NotificationHelper.showWarningSnackBar(context, '이미지를 선택해주세요.');
        return;
      }

      File imageFile = File(image.path);

      // 파일 크기 확인 (5MB 제한)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        NotificationHelper.showErrorSnackBar(context, '이미지 파일이 너무 큽니다. (최대 5MB)');
        return;
      }

      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      bool success = await plantProvider.registerPlantWithAI(imageFile);

      if (success) {
        Navigator.of(context).pop();
        NotificationHelper.showSuccessSnackBar(context, 'AI 인식으로 식물이 성공적으로 등록되었습니다!');
      } else {
        NotificationHelper.showErrorSnackBar(context, plantProvider.error ?? 'AI 인식에 실패했습니다.');
      }

    } catch (e) {
      NotificationHelper.showErrorSnackBar(context, 'AI 인식 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isAIProcessing = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('이미지 선택'),
          content: Text('어떤 방법으로 식물 사진을 선택하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 18),
                  SizedBox(width: 4),
                  Text('갤러리'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 18),
                  SizedBox(width: 4),
                  Text('카메라'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                        onPressed: (plantProvider.isLoading || _isAIProcessing) ? null : () {
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
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: _isAIProcessing
                ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
            )
                : Icon(
              Icons.photo_camera,
              size: 50,
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _isAIProcessing ? 'AI가 식물을 인식하는 중...' : 'AI 식물 인식',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxWidth: 280),
            child: Text(
              _isAIProcessing
                  ? '잠시만 기다려주세요. PlantNet AI가 식물을 분석하고 있습니다.'
                  : '카메라 또는 갤러리에서 식물 사진을 선택하여 자동으로 등록하세요. 잎이 선명하게 보이는 사진이 가장 좋습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),

          if (!_isAIProcessing) ...[
            ElevatedButton.icon(
              onPressed: () => _handleAIRegistration(context),
              icon: Icon(Icons.photo_camera),
              label: Text('사진으로 인식'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI 인식을 위해 인터넷 연결이 필요합니다.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isAIProcessing) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '인식 중... 10-30초 정도 소요됩니다.',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.eco_outlined),
          ),
          onChanged: (value) {
            setState(() {
              _plantName = value;
            });
          },
          enabled: !(_isAIProcessing || Provider.of<PlantProvider>(context, listen: false).isLoading),
        ),

        SizedBox(height: 16),

        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: '식물 종류',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.local_florist_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: _plantSpecies.isEmpty ? null : _plantSpecies,
          menuMaxHeight: 300,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down),
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
          ),
          onChanged: (_isAIProcessing || Provider.of<PlantProvider>(context, listen: false).isLoading)
              ? null
              : (String? value) {
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
              final isLoading = plantProvider.isLoading || _isAIProcessing;
              return ElevatedButton.icon(
                onPressed: isLoading ? null : () => _handleSubmit(context),
                icon: isLoading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.add_circle_outline),
                label: Text(
                  isLoading ? '등록 중...' : '식물 등록',
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