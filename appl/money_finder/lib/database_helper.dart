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

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(''' 
          CREATE TABLE income (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL,
            date TEXT,
            category TEXT
          );
          CREATE TABLE expense (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL,
            date TEXT,
            category TEXT
          );
        ''');
      },
    );
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
    return db.query('income', where: 'date LIKE ?', whereArgs: ['%$month%']);
  }

  Future<List<Map<String, dynamic>>> getExpenseByMonth(String month) async {
    final db = await database;
    return db.query('expense', where: 'date LIKE ?', whereArgs: ['%$month%']);
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
