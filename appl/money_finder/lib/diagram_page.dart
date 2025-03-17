import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class DiagramPage extends StatefulWidget {
  @override
  _DiagramPageState createState() => _DiagramPageState();
}

class _DiagramPageState extends State<DiagramPage> {
  String currentMonth = '2025-03';
  double totalIncome = 0;
  double totalExpense = 0;
  double balance = 0;
  Map<String, double> categoryExpenses = {};
  List<Map<String, dynamic>> incomeList = [];
  List<Map<String, dynamic>> expenseList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Загружаем данные о доходах и расходах за месяц
  _loadData() async {
    // Сначала сбрасываем все значения
    totalExpense = 0;
    categoryExpenses.clear();
    incomeList.clear();
    expenseList.clear();

    // Загружаем доходы и расходы для текущего месяца
    var incomes = await DatabaseHelper().getIncomeByMonth(currentMonth);
    var expenses = await DatabaseHelper().getExpenseByMonth(currentMonth);

    double income = 0;
    Map<String, double> expenseCategories = {};

    // Подсчитываем доходы и добавляем в список
    for (var row in incomes) {
      income += row['amount'];
      incomeList.add(row); // Добавляем доход в список
    }

    // Подсчитываем расходы и добавляем в список
    for (var row in expenses) {
      totalExpense += row['amount'];
      String category = row['category'];
      if (expenseCategories.containsKey(category)) {
        expenseCategories[category] = expenseCategories[category]! + row['amount'];
      } else {
        expenseCategories[category] = row['amount'];
      }
      expenseList.add(row); // Добавляем расход в список
    }

    // Обновляем состояние после загрузки данных
    setState(() {
      totalIncome = income;
      balance = totalIncome - totalExpense;
      categoryExpenses = expenseCategories;
    });
  }

  // Смена месяца
  _changeMonth(int delta) {
    // Добавляем "01" как день в текущий месяц
    final currentDate = DateTime.parse('$currentMonth-01'); // Теперь дата в формате 'yyyy-MM-dd'

    // Изменяем месяц с учетом перехода через год
    final newMonth = currentDate.month + delta;
    final newYear = currentDate.year + (newMonth > 12 ? 1 : (newMonth < 1 ? -1 : 0));
    final correctedMonth = ((newMonth - 1) % 12 + 12) % 12 + 1; // Это гарантирует, что месяц всегда в диапазоне от 1 до 12

    final newDate = DateTime(newYear, correctedMonth, 1); // Устанавливаем день как 1

    setState(() {
      currentMonth = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
    });
    _loadData();
  }

  // Генерация случайных цветов
  Color _generateRandomColor() {
    Random random = Random();
    return Color.fromRGBO(random.nextInt(256), random.nextInt(256), random.nextInt(256), 1);
  }

  // Удаление записи с подтверждением
  _deleteRecord(BuildContext context, String type, int id) async {
    bool shouldDelete = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить этот ${type.toLowerCase()}?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Отмена'),
            onPressed: () {
              Navigator.pop(context, false); // Отменить удаление
            },
          ),
          CupertinoDialogAction(
            child: Text('Удалить'),
            onPressed: () {
              Navigator.pop(context, true); // Подтвердить удаление
            },
          ),
        ],
      ),
    );

    if (shouldDelete) {
      if (type == 'Доход') {
        await DatabaseHelper().deleteIncome(id);
      } else if (type == 'Расход') {
        await DatabaseHelper().deleteExpense(id);
      }
      _loadData(); // Обновляем данные после удаления
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Выбор месяца
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                currentMonth,
                style: TextStyle(fontSize: 24),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),

          // Отображение статистики
          Text('Доходы: \$${totalIncome.toStringAsFixed(2)}'),
          Text('Расходы: \$${totalExpense.toStringAsFixed(2)}'),
          Text('Баланс: \$${balance.toStringAsFixed(2)}'),

          // Диаграмма расходов по категориям
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categoryExpenses.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value,
                      title: entry.key,
                      color: _generateRandomColor(), // Генерация случайного цвета для каждой категории
                      radius: 50,
                      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Список доходов
          Expanded(
            child: ListView(
              children: [
                // Секция доходов
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Доходы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...incomeList.map((income) {
                  return ListTile(
                    title: Text('Сумма: \$${income['amount']}'),
                    subtitle: Text('Категория: ${income['category']}'),
                    trailing: Text(income['date']),
                    onLongPress: () {
                      // Удаление записи о доходе
                      _deleteRecord(context, 'Доход', income['id']);
                    },
                  );
                }).toList(),

                // Секция расходов
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Расходы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...expenseList.map((expense) {
                  return ListTile(
                    title: Text('Сумма: \$${expense['amount']}'),
                    subtitle: Text('Категория: ${expense['category']}'),
                    trailing: Text(expense['date']),
                    onLongPress: () {
                      // Удаление записи о расходе
                      _deleteRecord(context, 'Расход', expense['id']);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
