import 'package:flutter/material.dart';
import 'package:studyshare/views/home/account/account_page.dart';
import 'package:studyshare/views/home/calendar/calendar_page.dart';
import 'package:studyshare/views/home/directories/classrooms_page.dart';
import 'package:studyshare/views/home/error_page.dart';
import 'package:studyshare/views/home/overview/overview_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

  @override
  void initState() {
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_sharp),
            label: "Kalender",
          ),
          NavigationDestination(
            icon: Icon(Icons.class_),
            label: "Kelas",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_rounded),
            label: "Akun",
          ),
        ],
      ),
      body: switch (_selectedIndex) {
        0 => const OverviewPage(),
        1 => const CalendarPage(),
        2 => const ClassroomsPage(),
        3 => const AccountPage(),
        _ => const ErrorPage(),
      },
    );
  }
}
