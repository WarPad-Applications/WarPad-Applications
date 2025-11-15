// Lokasi: lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'products';

  // Data awal produk Nasi Padang
  final List<Product> _initialProducts = [
    Product(
      title: 'Rendang Sapi',
      price: 30000,
      imageUrl: 'https://picsum.photos/seed/rendang/600/400',
    ),
    Product(
      title: 'Gulai Ayam',
      price: 22000,
      imageUrl: 'https://picsum.photos/seed/gulaiayam/600/400',
    ),
    Product(
      title: 'Dendeng Balado',
      price: 28000,
      imageUrl: 'httpsum.photos/seed/dendeng/600/400',
    ),
    Product(
      title: 'Sate Padang',
      price: 25000,
      imageUrl: 'https://picsum.photos/seed/satepadang/600/400',
    ),
    Product(
      title: 'Gulai Ikan',
      price: 20000,
      imageUrl: 'https://picsum.photos/seed/gulaiikan/600/400',
    ),
    Product(
      title: 'Daun Singkong',
      price: 10000,
      imageUrl: 'https://picsum.photos/seed/singkong/600/400',
    ),
  ];

  // Getter DB
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Init DB
  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'nasipadang.db');

    // ❗ Hanya hapus database UNTUK DEBUG
    // Comment baris di bawah kalau ingin database PERSISTEN

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            price INTEGER NOT NULL,
            imageUrl TEXT NOT NULL
          )
        ''');

        await _insertInitialData(db);
      },
    );
  }

  // Masukkan data awal
  Future<void> _insertInitialData(Database db) async {
    final batch = db.batch();
    for (var p in _initialProducts) {
      batch.insert(_tableName, p.toMap());
    }
    await batch.commit();
    print("DEBUG: Inserted ${_initialProducts.length} initial products");
  }

  // Ambil semua produk
  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    print("DEBUG: jumlah baris dalam tabel $_tableName = ${maps.length}");

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }
}
