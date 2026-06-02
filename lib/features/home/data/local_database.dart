import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartsync_runs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Si quieres borrar la BD en pruebas, puedes descomentar la siguiente línea:
    // await deleteDatabase(path);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE race_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          raceId TEXT NOT NULL,
          raceName TEXT NOT NULL,
          timeInSeconds INTEGER NOT NULL,
          isDisqualified INTEGER NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE location_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        speed REAL NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE race_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raceId TEXT NOT NULL,
        raceName TEXT NOT NULL,
        timeInSeconds INTEGER NOT NULL,
        isDisqualified INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertLocation(double lat, double lon, double speed) async {
    final db = await instance.database;
    await db.insert('location_points', {
      'latitude': lat,
      'longitude': lon,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'speed': speed,
      'is_synced': 0 // 0 = Aún no sube a Firebase
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    final db = await instance.database;
    return await db.query('location_points', where: 'is_synced = ?', whereArgs: [0], orderBy: 'timestamp ASC');
  }

  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    await db.update(
      'location_points', 
      {'is_synced': 1}, 
      where: 'id IN (${List.filled(ids.length, '?').join(',')})', 
      whereArgs: ids,
    );
  }

  Future<void> clearAllLocations() async {
    final db = await instance.database;
    await db.delete('location_points');
  }

  Future<void> saveRaceHistory(String raceId, String raceName, int timeInSeconds, bool isDisqualified) async {
    final db = await instance.database;
    await db.insert('race_history', {
      'raceId': raceId,
      'raceName': raceName,
      'timeInSeconds': timeInSeconds,
      'isDisqualified': isDisqualified ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getRaceHistory() async {
    final db = await instance.database;
    return await db.query('race_history', orderBy: 'timestamp DESC');
  }
}
