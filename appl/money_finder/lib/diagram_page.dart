import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'dart:math';

class DiagramPage extends StatefulWidget {
  @override
  _DiagramPageState createState() => _DiagramPageState();
}

class _DiagramPageState extends State<DiagramPage> with SingleTickerProviderStateMixin {
  String currentMonth = '2025-03';
  double totalIncome = 0;
  double totalExpense = 0;
  double balance = 0;
  Map<String, double> categoryExpenses = {};
  Map<String, double> categoryIncomes = {};
  List<Map<String, dynamic>> incomeList = [];
  List<Map<String, dynamic>> expenseList = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Загружаем данные о доходах и расходах за месяц
  _loadData() async {
    totalIncome = 0;
    totalExpense = 0;
    categoryExpenses.clear();
    categoryIncomes.clear();

    var incomes = await DatabaseHelper().getIncomeByMonth(currentMonth);
    var expenses = await DatabaseHelper().getExpenseByMonth(currentMonth);

    double income = 0;
    Map<String, double> incomeCategories = {};
    Map<String, double> expenseCategories = {};

    for (var row in incomes) {
      income += row['amount'];
      String category = row['category'] ?? 'Без категории';
      if (incomeCategories.containsKey(category)) {
        incomeCategories[category] = incomeCategories[category]! + row['amount'];
      } else {
        incomeCategories[category] = row['amount'];
      }
    }

    for (var row in expenses) {
      totalExpense += row['amount'];
      String category = row['category'];
      if (expenseCategories.containsKey(category)) {
        expenseCategories[category] = expenseCategories[category]! + row['amount'];
      } else {
        expenseCategories[category] = row['amount'];
      }
    }

    setState(() {
      totalIncome = income;
      balance = totalIncome - totalExpense;
      categoryExpenses = expenseCategories;
      categoryIncomes = incomeCategories;
      incomeList = incomes;
      expenseList = expenses;
    });
  }

  // Смена месяца
  _changeMonth(int delta) {
    final currentDate = DateTime.parse('$currentMonth-01');
    final newMonth = currentDate.month + delta;
    final newYear = currentDate.year + (newMonth > 12 ? 1 : (newMonth < 1 ? -1 : 0));
    final correctedMonth = ((newMonth - 1) % 12 + 12) % 12 + 1;

    setState(() {
      currentMonth = '${newYear}-${correctedMonth.toString().padLeft(2, '0')}';
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
              Navigator.pop(context, false);
            },
          ),
          CupertinoDialogAction(
            child: Text('Удалить'),
            onPressed: () {
              Navigator.pop(context, true);
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
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Статистика'),
            Text(
              'Баланс: ${balance.toStringAsFixed(2)} Руб.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Расходы'),
            Tab(text: 'Доходы'),
          ],
        ),
      ),
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Расходы
                Column(
                  children: [
                    Text('Общие расходы: ${totalExpense.toStringAsFixed(2)} Руб.'),
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
                                color: _generateRandomColor(),
                                radius: 50,
                                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: expenseList.map((expense) {
                          return ListTile(
                            title: Text('Сумма: ${expense['amount']} Руб.'),
                            subtitle: Text('Категория: ${expense['category']}\nКомментарий: ${expense['coment'] ?? "Нет"}'),
                            trailing: Text(expense['date']),
                            onLongPress: () {
                              _deleteRecord(context, 'Расход', expense['id']);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                // Доходы
                Column(
                  children: [
                    Text('Общие доходы: ${totalIncome.toStringAsFixed(2)} Руб.'),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: categoryIncomes.entries.map((entry) {
                              return PieChartSectionData(
                                value: entry.value,
                                title: entry.key,
                                color: _generateRandomColor(),
                                radius: 50,
                                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: incomeList.map((income) {
                          return ListTile(
                            title: Text('Сумма: ${income['amount']} Руб.'),
                            subtitle: Text('Категория: ${income['category']}\nКомментарий: ${income['coment'] ?? "Нет"}'),
                            trailing: Text(income['date']),
                            onLongPress: () {
                              _deleteRecord(context, 'Доход', income['id']);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
