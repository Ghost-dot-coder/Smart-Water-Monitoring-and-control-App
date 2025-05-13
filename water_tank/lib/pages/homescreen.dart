import 'package:flutter/material.dart';
import 'package:water_tank/pages/dashboard.dart';
import 'package:water_tank/pages/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track the selected tab

  // List of pages
  final List<Widget> _pages = [
    const Dashboard(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Show selected page

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight selected icon
        onTap: _onItemTapped, // Handle navigation
        selectedItemColor: Colors.blue, // Active color
        unselectedItemColor: Colors.grey, // Inactive color
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Dashboard Page

// Settings Page
