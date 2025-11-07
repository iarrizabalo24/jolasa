/*
 * Este archivo reemplaza al antiguo 'product_db.dart'.
 * Gestiona toda la base de datos local (Sqflite).
 * Es el único servicio que debe hablar con Sqflite.
 */
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fluttergame/models/product.dart';
import 'package:fluttergame/models/gamescore.dart'; // Asegúrate que este archivo exista

class LocalDbService {
  static Database? _database;
  static const String _dbName = 'jokoa.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Creación de las tablas locales
  Future<void> _createDB(Database db, int version) async {
    // Tabla de productos (para el juego 'prezioasmatu')
    // Usa los nombres 'izena' y 'prezioa'
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        izena TEXT NOT NULL,
        prezioa REAL NOT NULL
      )
    ''');

    // Tabla de puntuaciones (para el ranking y sincronización)
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        date TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  //===============================================
  // MÉTODOS DE PRODUCTOS
  //===============================================

  /// Borra todos los productos y guarda los nuevos de Odoo.
  /// Esto es una sincronización destructiva.
  Future<void> syncProducts(List<Product> products) async {
    final db = await database;
    // Usar un batch para eficiencia
    final batch = db.batch();

    // 1. Borrar todos los productos antiguos
    batch.delete('products');

    // 2. Insertar los nuevos
    for (var product in products) {
      batch.insert(
        'products',
        product.toSqfliteMap(), // Usa .toMap() del modelo Product
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    print('Productos sincronizados localmente: ${products.length}');
  }

  /// Obtiene los productos locales para el juego (lógica de ealberdi).
  Future<List<Product>> getLocalProducts() async {
    final db = await database;
    final res = await db.query('products', orderBy: 'izena ASC');
    // Usa .fromMap() del modelo Product
    return res.map((map) => Product.fromSqflite(map)).toList();
  }

  /// Inserta un nuevo producto manualmente (para AdminScreen)
  Future<void> addProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toSqfliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si el ID ya existe
    );
    print('Producto ${product.izena} guardado localmente.');
  }

  /// Borra un producto por su ID (para AdminScreen)
  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Producto $id borrado localmente.');
  }

  //===============================================
  // MÉTODOS DE PUNTUACIONES (SCORES)
  //===============================================

  /// Guarda una puntuación en local.
  /// 'isSynced' será 'false' si se guarda offline.
  Future<void> saveScoreLocally(GameScore score) async {
    final db = await database;
    await db.insert(
      'scores',
      score.toMap(), // Usa .toMap() del modelo GameScore
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Puntuación guardada localmente para ${score.userName}');
  }

  /// Obtiene todas las puntuaciones locales (para ranking offline).
  Future<List<GameScore>> getLocalScores() async {
    final db = await database;
    final res =
    await db.query('scores', orderBy: 'score DESC', limit: 50);
    // Usa .fromMap() del modelo GameScore
    return res.map((map) => GameScore.fromMap(map)).toList();
  }

  /// Obtiene solo las puntuaciones pendientes de subir a Odoo.
  Future<List<GameScore>> getPendingSyncScores() async {
    final db = await database;
    final res = await db.query(
      'scores',
      where: 'is_synced = ?',
      whereArgs: [0], // 0 = false
    );
    return res.map((map) => GameScore.fromMap(map)).toList();
  }

  /// Marca una lista de puntuaciones como "sincronizadas".
  Future<void> markScoresAsSynced(List<int> localIds) async {
    final db = await database;
    final batch = db.batch();
    for (var id in localIds) {
      batch.update(
        'scores',
        {'is_synced': 1}, // 1 = true
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
    print('Marcadas ${localIds.length} puntuaciones como sincronizadas.');
  }
}