import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  String selectedType = 'income'; // 'income' or 'expense'

  void _addTransaction() async {
    double amount = double.parse(_amountController.text);
    String category = _categoryController.text;
    String date = DateTime.now().toString().split(' ')[0]; // current date

    if (selectedType == 'income') {
      await DatabaseHelper().insertIncome(amount, date, category);
    } else {
      await DatabaseHelper().insertExpense(amount, date, category);
    }

    _amountController.clear();
    _categoryController.clear();
    setState(() {});
  }

  void _removeTransaction(int id) async {
    if (selectedType == 'income') {
      await DatabaseHelper().deleteIncome(id);
    } else {
      await DatabaseHelper().deleteExpense(id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Добавить транзакцию')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue!;
                });
              },
              items: <String>['income', 'expense']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'income' ? 'Доход' : 'Расход'),
                );
              }).toList(),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Сумма'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Категория'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTransaction,
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
