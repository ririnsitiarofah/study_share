import 'package:studyshare/views/home/directories/add_folder_dialog.dart';
import 'package:studyshare/views/home/directories/add_post_dialog.dart';
import 'package:studyshare/views/home/directories/classroom_list_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class DirectoriesWrapperPage extends StatelessWidget {
  const DirectoriesWrapperPage({Key? key});

  @override
  Widget build(BuildContext context) {
    BuildContext tabContext = context;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Berkas"),
          bottom: TabBar(
            onTap: (index) {},
            tabs: [
              Tab(
                text: ("Kelas"),
              ),
              Tab(
                text: ("Kelompok"),
              ),
              Tab(
                text: ("Personal"),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ClassroomListTab(),
            Center(child: Text("Kelompok Tab")),
            Center(child: Text("Personal Tab")),
          ],
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.add_box_rounded,
          shape: Theme.of(tabContext).floatingActionButtonTheme.shape ??
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
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddPostDialog()));
                },
                child: Icon(Icons.post_add_rounded)),
            SpeedDialChild(
              label: ('Buat folder'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFolderDialog(),
                  ),
                );
              },
              child: Icon(Icons.create_new_folder),
            )
          ],
        ),
      ),
    );
  }
}
