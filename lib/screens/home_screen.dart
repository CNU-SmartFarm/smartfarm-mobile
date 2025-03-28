import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../models/plant.dart';
import '../models/plant_species.dart';
import 'add_plant_screen.dart';
import 'detail_screen.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 식물'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading && plantProvider.plants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plantProvider.error != null && plantProvider.plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(plantProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => plantProvider.refreshPlantsData(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (plantProvider.plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, size: 72, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('아직 등록된 식물이 없습니다'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addNewPlant(context),
                    child: const Text('새 식물 추가하기'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => plantProvider.refreshPlantsData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plantProvider.plants.length,
              itemBuilder: (context, index) {
                final plant = plantProvider.plants[index];
                final species = plantProvider.getSpeciesById(plant.speciesId);

                return PlantCard(
                  plant: plant,
                  species: species,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantDetailScreen(plantId: plant.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewPlant(context),
        child: const Icon(Icons.add),
        tooltip: '새 식물 추가',
      ),
    );
  }

  void _addNewPlant(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPlantScreen(),
      ),
    );
  }
}

class PlantCard extends StatelessWidget {
  final Plant plant;
  final PlantSpecies? species;
  final VoidCallback onTap;

  const PlantCard({
    required this.plant,
    required this.species,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species?.name ?? '알 수 없는 식물',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusIndicator(),
                ],
              ),
              if (plant.latestData != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSensorInfo(
                      Icons.thermostat,
                      '${plant.latestData!.temperature.toStringAsFixed(1)}°C',
                      '온도',
                    ),
                    _buildSensorInfo(
                      Icons.water_drop,
                      '${plant.latestData!.humidity.toStringAsFixed(1)}%',
                      '습도',
                    ),
                    _buildSensorInfo(
                      Icons.wb_sunny,
                      '${plant.latestData!.light.toInt()} lux',
                      '조도',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (plant.latestData == null || species == null) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    bool isHealthy = plant.isEnvironmentSuitable(species!);

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSensorInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade700,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}