import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'diagram_page.dart';
import 'add_page.dart';

void main() {
   debugPaintSizeEnabled = false;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Two Pages App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DiagramPage(),
    AddPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Учет расходов'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 226, 226, 226),  // Вместо Center, это автоматически выровняет заголовок по центру
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Диаграмма',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_card),
            label: 'Добавить',
          ),
        ],
      ),
    );
  }
}
