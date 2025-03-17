import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    final db = await openDatabase(
      path,
      version: 1, // Установим версию базы данных
      onCreate: (db, version) async {
        // При создании базы данных создаем таблицы
        await _createTables(db);
      },
    );

    // Проверка наличия таблиц после создания базы данных
    await _checkTables(db);

    return db;
  }

  // Создание таблиц, если они не существуют
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        date TEXT,
        category TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        date TEXT,
        category TEXT
      );
    ''');
  }

  // Проверка таблиц в базе данных
  Future<void> _checkTables(Database db) async {
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table";');

    print('Tables in database:');
    for (var row in result) {
      print(row['name']);
    }

    // Проверяем, что таблицы "income" и "expense" существуют
    if (!result.any((row) => row['name'] == 'income')) {
      print('Income table not found!');
    }
    if (!result.any((row) => row['name'] == 'expense')) {
      print('Expense table not found!');
    }
  }

  Future<int> insertIncome(double amount, String date, String category) async {
    final db = await database;
    return db.insert('income', {'amount': amount, 'date': date, 'category': category});
  }

  Future<int> insertExpense(double amount, String date, String category) async {
    final db = await database;
    return db.insert('expense', {'amount': amount, 'date': date, 'category': category});
  }

  Future<List<Map<String, dynamic>>> getIncomeByMonth(String month) async {
  final db = await database;
  
  // Преобразуем месяц в формат 'YYYY-MM' (например, '2025-03')
  String formattedMonth = month.substring(0, 7);  // Получаем первые 7 символов 'YYYY-MM'
  
  return db.query(
    'income',
    where: 'date LIKE ?',
    whereArgs: ['$formattedMonth%'],  // Фильтруем только по месяцам
  );
}

Future<List<Map<String, dynamic>>> getExpenseByMonth(String month) async {
  final db = await database;
  
  // Преобразуем месяц в формат 'YYYY-MM' (например, '2025-03')
  String formattedMonth = month.substring(0, 7);  // Получаем первые 7 символов 'YYYY-MM'
  
  return db.query(
    'expense',
    where: 'date LIKE ?',
    whereArgs: ['$formattedMonth%'],  // Фильтруем только по месяцам
  );
}


  Future<int> deleteIncome(int id) async {
    final db = await database;
    return db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expense', where: 'id = ?', whereArgs: [id]);
  }
}
