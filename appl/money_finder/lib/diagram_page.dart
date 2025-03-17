import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    var incomes = await DatabaseHelper().getIncomeByMonth(currentMonth);
    var expenses = await DatabaseHelper().getExpenseByMonth(currentMonth);

    double income = 0;
    Map<String, double> expenseCategories = {};

    for (var row in incomes) {
      income += row['amount'];
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
    });
  }

  _changeMonth(int delta) {
    final currentDate = DateTime.parse(currentMonth);
    final newDate = DateTime(currentDate.year, currentDate.month + delta, currentDate.day);
    setState(() {
      currentMonth = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Статистика')),
      ),
      body: Column(
        children: [
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
          Text('Доходы: \$${totalIncome.toStringAsFixed(2)}'),
          Text('Расходы: \$${totalExpense.toStringAsFixed(2)}'),
          Text('Баланс: \$${balance.toStringAsFixed(2)}'),
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
                      color: Colors.blue,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
