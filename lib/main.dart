import 'package:flutter/material.dart';
import 'package:smartfarm/plant.dart';
import 'package:smartfarm/PlantSelectionPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "플랜챗",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      ),
      home: PlantSelectionPage(),
    );
  }
}