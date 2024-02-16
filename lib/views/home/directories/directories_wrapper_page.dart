import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:studyshare/views/home/directories/add_folder_dialog.dart';
import 'package:studyshare/views/home/directories/add_post_dialog.dart';
import 'package:studyshare/views/home/directories/chat_page.dart';
import 'package:studyshare/views/home/directories/classroom_detail_page.dart';
import 'package:studyshare/views/home/directories/directories_page.dart';
import 'package:studyshare/views/home/directories/events_page.dart';
import 'package:studyshare/views/home/directories/tasks_page.dart';
import 'package:studyshare/views/home/error_page.dart';

class DirectoriesWrapperPage extends StatefulWidget {
  const DirectoriesWrapperPage({
    super.key,
    required this.idKelas,
    required this.namaKelas,
    required this.idDirektori,
    required this.namaDirektori,
  });

  final String idKelas;
  final String namaKelas;
  final String? idDirektori;
  final String? namaDirektori;

  @override
  State<DirectoriesWrapperPage> createState() => _DirectoriesWrapperPageState();
}

class _DirectoriesWrapperPageState extends State<DirectoriesWrapperPage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        Navigator.pop(context);
      },
      child: Scaffold(
        floatingActionButton: _selectedIndex == 0
            ? SpeedDial(
                heroTag: 'fab',
                icon: Icons.add,
                shape: Theme.of(context).floatingActionButtonTheme.shape ??
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(16),
                      ),
                    ),
                activeIcon: Icons.close,
                childrenButtonSize: const Size.square(48),
                spaceBetweenChildren: 16,
                childPadding: const EdgeInsets.all(4),
                children: [
                  SpeedDialChild(
                    label: ("Buat Postingan"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => AddPostDialog(
                            idParent: widget.idDirektori,
                            idKelas: widget.idKelas,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.post_add_rounded),
                  ),
                  SpeedDialChild(
                    label: ('Buat folder'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => AddFolderDialog(
                            idParent: widget.idDirektori,
                            idKelas: widget.idKelas,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.create_new_folder),
                  )
                ],
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder),
              label: "Berkas",
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment),
              label: "Tugas",
            ),
            NavigationDestination(
              icon: Icon(Icons.event),
              label: "Acara",
            ),
            NavigationDestination(
              icon: Icon(Icons.chat),
              label: "Obrolan",
            ),
          ],
        ),
        body: switch (_selectedIndex) {
          0 => DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
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
                          child: Text(widget.namaDirektori ?? widget.namaKelas),
                        ),
                      ),
                    ),
                    actions: [
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'info',
                            child: Text("Info kelas"),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'info':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClassroomDetailPage(
                                    idKelas: widget.idKelas,
                                  ),
                                ),
                              );
                              break;
                          }
                        },
                      ),
                    ],
                    bottom: TabBar(
                      onTap: (index) {},
                      tabs: const [
                        Tab(
                          text: ("Kelas"),
                        ),
                        Tab(
                          text: ("Personal"),
                        ),
                      ],
                    ),
                  )
                ],
                body: TabBarView(
                  children: [
                    DirectoriesPage(
                      isKelas: true,
                      idKelas: widget.idKelas,
                      namaKelas: widget.namaKelas,
                      idDirektori: widget.idDirektori,
                      namaDirektori: widget.namaDirektori,
                    ),
                    DirectoriesPage(
                      isKelas: false,
                      idKelas: widget.idKelas,
                      namaKelas: widget.namaKelas,
                      idDirektori: widget.idDirektori,
                      namaDirektori: widget.namaDirektori,
                    ),
                  ],
                ),
              ),
            ),
          1 => TasksPage(
              idKelas: widget.idKelas,
            ),
          2 => EventsPage(
              idKelas: widget.idKelas,
            ),
          3 => ChatPage(
              idKelas: widget.idKelas,
              namaKelas: widget.namaKelas,
            ),
          _ => const ErrorPage(),
        },
      ),
    );
  }
}
