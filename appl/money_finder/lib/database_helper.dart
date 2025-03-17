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

    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await _createTables(db);
        },
      );
    } catch (e) {
      print("Error initializing database: $e");
      rethrow;
    }
  }

  Future<void> _createTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS income (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL,
          date TEXT,
          coment TEXT,
          category TEXT
        );
      ''');
      // Таблица категорий
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    // Добавление стандартных категорий
    const defaultCategories = ['Еда', 'Транспорт', 'Развлечения', 'Одежда', 'Здоровье'];
    for (var category in defaultCategories) {
      await db.insert(
        'categories',
        {'name': category},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  // Таблица категорий доходов
    await db.execute(''' 
      CREATE TABLE IF NOT EXISTS income_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    const defaultIncomeCategories = ['Зарплата', 'Подарки', 'Инвестиции', 'Прочее'];
    for (var category in defaultIncomeCategories) {
      await db.insert(
        'income_categories',
        {'name': category},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
      

      await db.execute('''
        CREATE TABLE IF NOT EXISTS expense (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL,
          date TEXT,
          category TEXT,
          coment TEXT
        );
      ''');
    } catch (e) {
      print("Error creating tables: $e");
    }
  }

  Future<int> insertIncome(double amount, String date, String coment, String category) async {
    try {
      final db = await database;
      return db.insert('income', {
        'amount': amount,
        'date': date,
        'coment': coment,
        'category': category
      });
    } catch (e) {
      print("Error inserting income: $e");
      return -1;
    }
  }

  Future<int> insertExpense(
      double amount, String date, String category, String coment) async {
    try {
      final db = await database;
      return db.insert('expense', {
        'amount': amount,
        'date': date,
        'category': category,
        'coment': coment,
      });
    } catch (e) {
      print("Error inserting expense: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getIncomeByMonth(String month) async {
    try {
      final db = await database;
      String formattedMonth = month.substring(0, 7);
      return db.query(
        'income',
        where: 'date LIKE ?',
        whereArgs: ['$formattedMonth%'],
      );
    } catch (e) {
      print("Error fetching income by month: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseByMonth(String month) async {
    try {
      final db = await database;
      String formattedMonth = month.substring(0, 7);
      return db.query(
        'expense',
        where: 'date LIKE ?',
        whereArgs: ['$formattedMonth%'],
      );
    } catch (e) {
      print("Error fetching expense by month: $e");
      return [];
    }
  }

  Future<int> deleteIncome(int id) async {
    try {
      final db = await database;
      return db.delete('income', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error deleting income: $e");
      return -1;
    }
  }

  Future<int> deleteExpense(int id) async {
    try {
      final db = await database;
      return db.delete('expense', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error deleting expense: $e");
      return -1;
    }
  }
}
