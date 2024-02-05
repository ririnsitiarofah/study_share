import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:studyshare/views/classroom/create_classroom.dart';
import 'package:studyshare/views/classroom/join_page.dart';
import 'package:studyshare/views/home/directories/directories_wrapper_page.dart';

class ClassroomsPage extends StatelessWidget {
  const ClassroomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text("Kelas"),
          )
        ],
        body: FirestoreListView(
          query: FirebaseFirestore.instance.collection('member_kelas').where(
              'id_user',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid),
          emptyBuilder: (context) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    size: 100,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    "Kamu belum bergabung dengan kelas apapun",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateClassroomPage(),
                            ),
                          );
                        },
                        child: const Text("Buat Kelas"),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinPage(),
                            ),
                          );
                        },
                        child: const Text("Join Kelas"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          padding: EdgeInsets.zero,
          itemBuilder: (context, snapshot) {
            final memberKelas = snapshot.data();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.class_),
                ),
                // trailing: PopupMenuButton(
                //   itemBuilder: (context) => [
                //     const PopupMenuItem(
                //       value: 'info',
                //       child: Text('Detail'),
                //     ),
                //   ],
                //   onSelected: (selectedItem) async {
                //     switch (selectedItem) {
                //       case 'info':
                //         break;
                //     }
                //   },
                // ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                title: Text(memberKelas["nama_kelas"] ?? 'asas'),
                tileColor: colorScheme.surfaceVariant,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectoriesWrapperPage(
                        idKelas: memberKelas["id_kelas"],
                        namaKelas: memberKelas["nama_kelas"],
                        idDirektori: null,
                        namaDirektori: null,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
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
            label: ("Buat Kelas"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateClassroomPage()),
              );
            },
            child: const Icon(Icons.school),
          ),
          SpeedDialChild(
            label: ('Join Kelas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinPage(),
                ),
              );
            },
            child: const Icon(Icons.login),
          )
        ],
      ),
    );
  }
}
