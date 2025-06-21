import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smartfarm.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 식물 테이블
    await db.execute('''
      CREATE TABLE plants(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        registeredDate TEXT NOT NULL,
        optimalTempMin REAL NOT NULL,
        optimalTempMax REAL NOT NULL,
        optimalHumidityMin REAL NOT NULL,
        optimalHumidityMax REAL NOT NULL,
        optimalSoilMoistureMin REAL NOT NULL,
        optimalSoilMoistureMax REAL NOT NULL,
        optimalLightMin REAL NOT NULL,
        optimalLightMax REAL NOT NULL,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // 센서 데이터 테이블
    await db.execute('''
      CREATE TABLE sensor_data(
        id TEXT PRIMARY KEY,
        plantId TEXT NOT NULL,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        soilMoisture REAL NOT NULL,
        light REAL NOT NULL,
        timestamp TEXT NOT NULL,
        lastSynced INTEGER DEFAULT 0,
        FOREIGN KEY (plantId) REFERENCES plants (id)
      )
    ''');

    // 알림 테이블
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY,
        plantId TEXT NOT NULL,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        lastSynced INTEGER DEFAULT 0,
        FOREIGN KEY (plantId) REFERENCES plants (id)
      )
    ''');

    // 설정 테이블
    await db.execute('''
      CREATE TABLE settings(
        userId TEXT PRIMARY KEY,
        pushNotificationEnabled INTEGER DEFAULT 1,
        language TEXT DEFAULT 'ko',
        theme TEXT DEFAULT 'light',
        lastSynced INTEGER DEFAULT 0
      )
    ''');
  }

  // 식물 데이터 CRUD
  Future<void> insertPlant(Map<String, dynamic> plant) async {
    final db = await database;
    await db.insert('plants', plant, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getPlant(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> updatePlant(String id, Map<String, dynamic> plant) async {
    final db = await database;
    await db.update(
      'plants',
      plant,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlant(String id) async {
    final db = await database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 센서 데이터 CRUD
  Future<void> insertSensorData(Map<String, dynamic> sensorData) async {
    final db = await database;
    await db.insert('sensor_data', sensorData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getLatestSensorData(String plantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_data',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getHistoricalSensorData(String plantId, String period) async {
    final db = await database;
    DateTime cutoffDate;

    switch (period) {
      case '24h':
        cutoffDate = DateTime.now().subtract(Duration(hours: 24));
        break;
      case '7d':
        cutoffDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case '30d':
        cutoffDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case '90d':
        cutoffDate = DateTime.now().subtract(Duration(days: 90));
        break;
      default:
        cutoffDate = DateTime.now().subtract(Duration(hours: 24));
    }

    return await db.query(
      'sensor_data',
      where: 'plantId = ? AND timestamp >= ?',
      whereArgs: [plantId, cutoffDate.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
  }

  // 알림 CRUD
  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    await db.insert('notifications', notification, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String plantId, {int limit = 10, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 설정 CRUD
  Future<void> insertOrUpdateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.insert('settings', settings, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getSettings(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}