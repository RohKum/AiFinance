import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:aifin/data/models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  type TEXT NOT NULL
)
''');
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllTransactions() async {
    final db = await instance.database;
    await db.delete('transactions');
  }
}
