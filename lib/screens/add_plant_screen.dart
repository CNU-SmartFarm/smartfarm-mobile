import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../models/plant_species.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({Key? key}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedSpeciesId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 식물 추가'),
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.species.isEmpty && plantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plantProvider.species.isEmpty) {
            return const Center(
              child: Text('사용 가능한 식물 종이 없습니다'),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정의 이름 입력 필드
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '식물 이름',
                      hintText: '예: 거실이, 창가의 친구 등',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '식물 이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 식물 종 선택 드롭다운
                  const Text(
                    '식물 종류',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSpeciesDropdown(plantProvider.species),

                  const SizedBox(height: 16),

                  // 선택한 식물 종의 정보 표시
                  if (_selectedSpeciesId != null) ...[
                    _buildSelectedSpeciesInfo(
                        plantProvider.getSpeciesById(_selectedSpeciesId!)
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _savePlant(plantProvider),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('식물 추가하기'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeciesDropdown(List<PlantSpecies> speciesList) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          hint: const Text('식물 종류를 선택하세요'),
          value: _selectedSpeciesId,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          validator: (value) {
            if (value == null) {
              return '식물 종류를 선택해주세요';
            }
            return null;
          },
          onChanged: (String? newValue) {
            setState(() {
              _selectedSpeciesId = newValue;
            });
          },
          items: speciesList.map<DropdownMenuItem<String>>((PlantSpecies species) {
            return DropdownMenuItem<String>(
              value: species.id,
              child: Text(species.name),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedSpeciesInfo(PlantSpecies? species) {
    if (species == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              species.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (species.description.isNotEmpty) ...[
              Text(species.description),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '적정 환경 조건',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEnvironmentInfoRow(
              Icons.thermostat,
              '온도',
              '${species.temperatureRange.min}-${species.temperatureRange.max}°C',
            ),
            _buildEnvironmentInfoRow(
              Icons.water_drop,
              '습도',
              '${species.humidityRange.min}-${species.humidityRange.max}%',
            ),
            _buildEnvironmentInfoRow(
              Icons.wb_sunny,
              '조도',
              '${species.lightRange.min.toInt()}-${species.lightRange.max.toInt()} lux',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  void _savePlant(PlantProvider plantProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plant = await plantProvider.addPlant(
        _nameController.text.trim(),
        _selectedSpeciesId!,
      );

      if (plant != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식물이 추가되었습니다')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(plantProvider.error ?? '식물 추가에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}