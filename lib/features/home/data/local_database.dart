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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Creamos la tabla donde se guardarán los puntos del mapa (Offline)
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
  }

  // MÉTODO 1: Guardar un punto del GPS
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

  // MÉTODO 2: Obtener puntos que NO se han subido a Firebase
  Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    final db = await instance.database;
    return await db.query('location_points', where: 'is_synced = ?', whereArgs: [0], orderBy: 'timestamp ASC');
  }

  // MÉTODO 3: Marcar puntos como "Ya subidos"
  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    await db.update(
      'location_points', 
      {'is_synced': 1}, 
      where: 'id IN (${ids.map((_) => '?').join(', ')})', 
      whereArgs: ids
    );
  }

  // MÉTODO 4: Limpiar la tabla (Al terminar la carrera)
  Future<void> clearRunData() async {
    final db = await instance.database;
    await db.delete('location_points');
  }
}
