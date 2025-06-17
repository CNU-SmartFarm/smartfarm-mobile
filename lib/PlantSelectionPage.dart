import 'package:flutter/material.dart';
import 'dart:developer';
import 'plant.dart';
import 'fetch_plants.dart';

class PlantSelectionPage extends StatefulWidget {
  const PlantSelectionPage({Key? key}) : super(key: key);

  @override
  State<PlantSelectionPage> createState() => _PlantSelectionPageState();
}

class _PlantSelectionPageState extends State<PlantSelectionPage> {
  List<String> plantNames = [];
  String apiKey = '202506169X0I9EUAH87VPSSINI3OYQ';
  late TextEditingController _controller;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadAllPlantsInitially();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlantsInitially() async {
    setState(() {
      _isLoading = true;
    });
    await fetchAndSetPlants('');
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAndSetPlants(String query) async {
    print('fetchAndSetPlants 함수 호출됨. 검색어: $query');
    try {
      final names = await fetchPlants(query, apiKey);
      setState(() {
        plantNames = names;
      });
    } catch (e) {
      setState(() => plantNames = []);
      print('에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    //TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.lightGreen.shade200,
        title: Text('식물 검색',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Galmuri',
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.lightGreen.shade600,
                offset: const Offset(2, 2),
              )
            ],
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '식물 이름 검색',
                labelStyle: TextStyle(color: Colors.lightGreen.shade700),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.lightGreen.shade500, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.lightGreen.shade300, width: 1),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.lightGreen.shade400),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  color: Colors.lightGreen.shade600,
                  onPressed: () {
                    fetchAndSetPlants(_controller.text);
                  },
                ),
                  fillColor: Colors.lightGreen.shade50,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10)
              ),
              cursorColor: Colors.lightGreen.shade700,
              style: const TextStyle(fontSize: 16),
              onSubmitted: fetchAndSetPlants,
            ),
          ),
          Expanded(
          child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightGreen))
        : plantNames.isEmpty
              ? Center(
              child: Text(
              '검색 결과가 없습니다.',
              style: TextStyle(
              fontSize: 18,
              color: Colors.lightGreen.shade700,
              fontWeight: FontWeight.w600,
              ),
              ),
              )
                  : ListView.builder(
              itemCount: plantNames.length,
              itemBuilder: (context, index) {
              return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
              plantNames[index],
              style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.green,
              ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.lightGreen.shade400),
              onTap: () {
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(
              builder: (context) => Plant(plantName: plantNames[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}
