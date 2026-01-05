import "package:flutter/material.dart";

class DashboardScreen  extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreen();

}

class _DashboardScreen extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    
    return  Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_sharp),label: "Add Post"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none),label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile")
        ]
        ),


      
    );
  }
}