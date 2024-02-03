import 'package:studyshare/views/home/account/account_page.dart';
import 'package:studyshare/views/home/calendar/calendar_page.dart';
import 'package:studyshare/views/home/directories/directories_wrapper_page.dart';
import 'package:studyshare/views/home/error_page.dart';
import 'package:studyshare/views/home/overview/overview_pade.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            print("nilai index sebelumnya: $_selectedIndex");
            _selectedIndex = index;
            print("nilai index setelah diubah: $_selectedIndex");
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_sharp),
            label: "Kalender",
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: "Berkas",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_rounded),
            label: "Akun",
          ),
        ],
      ),
      body: switch (_selectedIndex) {
        0 => OverviewPage(),
        1 => CalendarPage(),
        2 => DirectoriesWrapperPage(),
        3 => AccountPage(),
        _ => ErrorPage(),
      },
    );
  }
}
