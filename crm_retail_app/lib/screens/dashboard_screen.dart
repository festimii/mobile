import 'package:flutter/material.dart';
import 'package:crm_retail_app/screens/tabs/home_tab.dart';
import 'package:crm_retail_app/screens/tabs/sales_tab.dart';
import 'package:crm_retail_app/screens/tabs/inventory_tab.dart';
import 'package:crm_retail_app/screens/tabs/settings_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeTab(),
    SalesTab(),
    InventoryTab(),
    SettingsTab(),
  ];

  final List<String> _titles = ['Stores', 'B2B/C', 'Stock', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stores'),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'B2B/C',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
