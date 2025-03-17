import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController amountController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  String selectedDate = ''; // Для хранения выбранной даты

  @override
  void initState() {
    super.initState();
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Устанавливаем текущую дату по умолчанию
  }

  // Метод для выбора даты
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked); // Обновляем выбранную дату
      });
    }
  }

  // Метод для добавления дохода
  void _addIncome() async {
    double amount = double.parse(amountController.text);
    String category = categoryController.text;

    await DatabaseHelper().insertIncome(amount, selectedDate, category);

    // Очистка полей после добавления
    amountController.clear();
    categoryController.clear();
  }

  // Метод для добавления расхода
  void _addExpense() async {
    double amount = double.parse(amountController.text);
    String category = categoryController.text;

    await DatabaseHelper().insertExpense(amount, selectedDate, category);

    // Очистка полей после добавления
    amountController.clear();
    categoryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить данные'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Поле ввода суммы
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Сумма'),
            ),
            SizedBox(height: 16),
            
            // Поле ввода категории
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Категория'),
            ),
            SizedBox(height: 16),
            
            // Виджет для выбора даты
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
                Text('Выбранная дата: $selectedDate'),
              ],
            ),
            SizedBox(height: 16),
            
            // Кнопки для добавления дохода или расхода
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addIncome,
                  child: Text('Добавить доход'),
                ),
                ElevatedButton(
                  onPressed: _addExpense,
                  child: Text('Добавить расход'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
