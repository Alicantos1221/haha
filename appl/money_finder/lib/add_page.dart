import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  String _selectedType = 'Доход'; // Тип операции: Доход или Расход
  String? _selectedCategory; // Выбранная категория для расхода
  String? _selectedIncomeCategory; // Выбранная категория для дохода
  List<String> _categories = []; // Список категорий для расходов
  List<String> _incomeCategories = []; // Список категорий для доходов
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Текущая дата

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadIncomeCategories();
  }

  // Загрузка категорий расходов
  Future<void> _loadCategories() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('categories');
    setState(() {
      _categories = result.map((row) => row['name'] as String).toList();
    });
  }

  // Загрузка категорий доходов
  Future<void> _loadIncomeCategories() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('income_categories');
    setState(() {
      _incomeCategories = result.map((row) => row['name'] as String).toList();
    });
  }

  // Добавление новой категории расходов
  Future<void> _addCategory(String category) async {
    if (category.isEmpty) return;
    final db = await DatabaseHelper().database;
    await db.insert('categories', {'name': category},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    _loadCategories();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Категория добавлена')));
  }

  // Добавление новой категории дохода
  Future<void> _addIncomeCategory(String category) async {
    if (category.isEmpty) return;
    final db = await DatabaseHelper().database;
    await db.insert('income_categories', {'name': category},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    _loadIncomeCategories();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Категория дохода добавлена')));
  }

  // Сохранение записи
  Future<void> _saveRecord() async {
    try {
      if (_formKey.currentState!.validate()) {
        double amount = double.parse(_amountController.text);
        String comment = _commentController.text;

        if (_selectedType == 'Доход' && _selectedIncomeCategory != null) {
          await DatabaseHelper().insertIncome(amount, _selectedDate, comment, _selectedIncomeCategory!);
        } else if (_selectedType == 'Расход' && _selectedCategory != null) {
          await DatabaseHelper().insertExpense(
              amount, _selectedDate, _selectedCategory!, comment);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Запись успешно добавлена!'),
        ));
      }
    } catch (e) {
      print('Ошибка при сохранении записи: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка при сохранении записи: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Добавить запись')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор типа операции
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Тип: '),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: ['Доход', 'Расход']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _selectedCategory = null;
                        _selectedIncomeCategory = null;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Поле для ввода суммы
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Выпадающий список для выбора категории (для Дохода или Расхода)
              if (_selectedType == 'Доход')
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedIncomeCategory,
                        items: _incomeCategories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIncomeCategory = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Категория дохода',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_selectedType == 'Доход' && value == null) {
                            return 'Выберите категорию дохода';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Добавить категорию дохода'),
                            content: TextField(
                              controller: _newCategoryController,
                              decoration: InputDecoration(
                                  labelText: 'Название категории дохода'),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Отмена'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text('Добавить'),
                                onPressed: () {
                                  _addIncomeCategory(
                                      _newCategoryController.text.trim());
                                  _newCategoryController.clear();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              if (_selectedType == 'Расход')
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Категория расхода',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_selectedType == 'Расход' && value == null) {
                            return 'Выберите категорию';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Добавить категорию расхода'),
                            content: TextField(
                              controller: _newCategoryController,
                              decoration: InputDecoration(
                                  labelText: 'Название категории расхода'),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Отмена'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text('Добавить'),
                                onPressed: () {
                                  _addCategory(_newCategoryController.text.trim());
                                  _newCategoryController.clear();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              SizedBox(height: 16),

              // Поле для ввода комментария
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Комментарий',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),

              // Выбор даты
              Row(
                children: [
                  Text('Дата: $_selectedDate'),
                  Spacer(),
                  TextButton(
                    child: Text('Выбрать дату'),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Кнопка сохранения
              Center(
                child: ElevatedButton(
                  child: Text('Сохранить'),
                  onPressed: _saveRecord,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
