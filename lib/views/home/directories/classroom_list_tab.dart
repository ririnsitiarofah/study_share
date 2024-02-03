import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/core/utils/colors.dart';
import 'package:studyshare/views/home/directories/directories_page.dart';

enum PopupItem {
  edit,
  delete;
}

class ClassroomListTab extends StatelessWidget {
  const ClassroomListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FirestoreListView(
        query: FirebaseFirestore.instance
            .collection('member_kelas')
            .where('id_user', isEqualTo: 'QaMyRY0vcQeFSbLiiPzylhDxi6r2'),
        itemBuilder: (context, snapshot) {
          final memberKelas = snapshot.data();

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(colorPalettes
                    .firstWhere(
                        (palette) => palette.key == memberKelas["color"])
                    .color),
                child: Icon(Icons.folder),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) {
                  return PopupItem.values.map(
                    (item) {
                      return PopupMenuItem(
                        value: item,
                        child: Text(
                          () {
                            switch (item) {
                              case PopupItem.edit:
                                return 'Edit';
                              case PopupItem.delete:
                                return 'Delete';
                            }
                          }(),
                        ),
                      );
                    },
                  ).toList();
                },
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              title: Text(
                memberKelas["nama_kelas"],
              ),
              tileColor: colorScheme.surfaceVariant,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DirectoriesPage()),
                );
              },
            ),
          );
        });
  }
}
