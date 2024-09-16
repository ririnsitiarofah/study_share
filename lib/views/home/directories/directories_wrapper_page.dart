import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:studyshare/views/home/calendar/add_event_page.dart';
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
    this.initialTab = 0,
    this.tabController,
  });

  final String idKelas;
  final String namaKelas;
  final String? idDirektori;
  final String? namaDirektori;
  final int initialTab;
  final TabController? tabController;

  @override
  State<DirectoriesWrapperPage> createState() => _DirectoriesWrapperPageState();
}

class _DirectoriesWrapperPageState extends State<DirectoriesWrapperPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  var _selectedIndex = 0;
  var _selectedTabIndex = 0;

  late String _namaKelas;

  @override
  void initState() {
    _namaKelas = widget.namaKelas;
    _selectedIndex = widget.initialTab;

    if (widget.tabController != null) {
      _tabController = widget.tabController!;
      _selectedTabIndex = _tabController.index;
    } else {
      _tabController = TabController(length: 2, vsync: this)
        ..addListener(
          () {
            setState(() {
              _selectedTabIndex = _tabController.index;
            });
          },
        );
    }
    super.initState();
  }

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
        floatingActionButton: switch (_selectedIndex) {
          0 => SpeedDial(
              heroTag: 'fab',
              icon: Icons.add,
              label: _selectedTabIndex == 1 ? const Text("Personal") : null,
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
                          idKelas:
                              _selectedTabIndex == 0 ? widget.idKelas : null,
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
                          idKelas:
                              _tabController.index == 0 ? widget.idKelas : null,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.create_new_folder),
                )
              ],
            ),
          1 => FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => AddEventPage(
                      initialDate: DateTime.now(),
                      initialType: 'tugas',
                      changable: false,
                      initialIdKelas: widget.idKelas,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          2 => FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => AddEventPage(
                      initialDate: DateTime.now(),
                      initialType: 'acara',
                      changable: false,
                      initialIdKelas: widget.idKelas,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          _ => null,
        },
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
          0 => NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClassroomDetailPage(idKelas: widget.idKelas),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _namaKelas = result;
                        });
                      }
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: kToolbarHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(widget.namaDirektori ?? _namaKelas),
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
                    controller: _tabController,
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
                controller: _tabController,
                children: [
                  DirectoriesPage(
                    isKelas: true,
                    idKelas: widget.idKelas,
                    namaKelas: widget.namaKelas,
                    idDirektori: widget.idDirektori,
                    namaDirektori: widget.namaDirektori,
                    tabController: _tabController,
                  ),
                  DirectoriesPage(
                    isKelas: false,
                    idKelas: widget.idKelas,
                    namaKelas: widget.namaKelas,
                    idDirektori: widget.idDirektori,
                    namaDirektori: widget.namaDirektori,
                    tabController: _tabController,
                  ),
                ],
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
