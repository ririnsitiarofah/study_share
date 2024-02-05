import 'package:flutter/material.dart';
import 'package:studyshare/views/home/directories/chat_page.dart';
import 'package:studyshare/views/home/directories/classroom_detail_page.dart';
import 'package:studyshare/views/home/directories/directories_page.dart';
import 'package:studyshare/views/home/error_page.dart';

class DirectoriesWrapperPage extends StatefulWidget {
  const DirectoriesWrapperPage({
    super.key,
    required this.idKelas,
    required this.namaKelas,
  });

  final String idKelas;
  final String namaKelas;

  @override
  State<DirectoriesWrapperPage> createState() => _DirectoriesWrapperPageState();
}

class _DirectoriesWrapperPageState extends State<DirectoriesWrapperPage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClassroomDetailPage(idKelas: widget.idKelas),
                ),
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.namaKelas),
              ),
            ),
          ),
          bottom: _selectedIndex == 0
              ? TabBar(
                  onTap: (index) {},
                  tabs: const [
                    Tab(
                      text: ("Kelas"),
                    ),
                    Tab(
                      text: ("Personal"),
                    ),
                  ],
                )
              : null,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: "Berkas",
            ),
            NavigationDestination(
              icon: Icon(Icons.chat),
              label: "Obrolan",
            ),
          ],
        ),
        body: switch (_selectedIndex) {
          0 => TabBarView(
              children: [
                DirectoriesPage(
                  idKelas: widget.idKelas,
                  idDirektori: null,
                  namaDirektori: null,
                ),
                const DirectoriesPage(
                  idKelas: null,
                  idDirektori: null,
                  namaDirektori: null,
                ),
              ],
            ),
          1 => ChatPage(
              idKelas: widget.idKelas,
              namaKelas: widget.namaKelas,
            ),
          _ => const ErrorPage(),
        },
      ),
    );
  }
}
