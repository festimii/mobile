import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_retail_app/features/dashboard/tabs/home_tab.dart';
import 'package:crm_retail_app/features/dashboard/tabs/sales_tab.dart';
import 'package:crm_retail_app/features/dashboard/tabs/inventory_tab.dart';
import 'package:crm_retail_app/features/dashboard/tabs/settings_tab.dart';
import 'package:crm_retail_app/providers/date_provider.dart';

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
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          Consumer<DateProvider>(
            builder: (context, dateProvider, _) => IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateProvider.selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  dateProvider.setDate(picked);
                }
              },
            ),
          ),
        ],
      ),
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
