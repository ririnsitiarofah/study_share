import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:studyshare/views/home/directories/add_folder_dialog.dart';
import 'package:studyshare/views/home/directories/add_post_dialog.dart';

class DirectoriesPage extends StatelessWidget {
  const DirectoriesPage({
    super.key,
    required this.idKelas,
    required this.idDirektori,
    required this.namaDirektori,
  });

  final String? idKelas;
  final String? idDirektori;
  final String? namaDirektori;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final folderQuery = idKelas != null
        ? FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'folder')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isEqualTo: idKelas)
            .orderBy('nama')
        : FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'folder')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isEqualTo: null)
            .where('id_pemilik',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('nama');

    final postQuery = idKelas != null
        ? FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'postingan')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isEqualTo: idKelas)
            .orderBy('nama')
        : FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'postingan')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isEqualTo: null)
            .where('id_pemilik',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('nama');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Text("Folder"),
              ),
            ),
            FirestoreQueryBuilder(
              query: folderQuery,
              builder: (context, snapshot, child) {
                if (snapshot.isFetching) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text('Something went wrong! ${snapshot.error}'),
                    ),
                  );
                }

                if (snapshot.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text("Tidak ada folder"),
                        ),
                      ],
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                      snapshot.fetchMore();
                    }

                    final doc = snapshot.docs[index];
                    final data = doc.data();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(data['color'] ?? 0xffcd3676),
                          child: const Icon(Icons.folder),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                          onSelected: (selectedItem) async {
                            switch (selectedItem) {
                              case 'edit':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddFolderDialog(
                                      idParent: idDirektori,
                                      idKelas: idKelas,
                                      existingFolderId: doc.id,
                                      existingFolderName: data['nama'],
                                      existingFolderDesc: data['deskripsi'],
                                      existingFolderColor: data['warna'],
                                    ),
                                  ),
                                );
                                break;
                              case 'delete':
                                await FirebaseFirestore.instance
                                    .collection('direktori')
                                    .doc(doc.id)
                                    .delete();
                                break;
                            }
                          },
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        title: Text(data['nama']),
                        tileColor: colorScheme.surfaceVariant,
                        onTap: () {
                          // Hande tile tap if needed
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Text("Postingan"),
              ),
            ),
            FirestoreQueryBuilder(
              query: postQuery,
              builder: (context, snapshot, child) {
                if (snapshot.isFetching) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text('Something went wrong! ${snapshot.error}'),
                    ),
                  );
                }

                if (snapshot.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article,
                          size: 48,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text("Tidak ada postingan"),
                        ),
                      ],
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                      snapshot.fetchMore();
                    }

                    final doc = snapshot.docs[index];
                    final data = doc.data();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colorScheme.surfaceVariant,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['nama'],
                                      style: textTheme.titleMedium),
                                  if (data['deskripsi'] != null &&
                                      (data['deskripsi'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(data['deskripsi']),
                                  ],
                                  Row(
                                    children: [
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {},
                                        icon: const Icon(Icons.message),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                            onSelected: (selectedItem) async {
                              switch (selectedItem) {
                                case 'edit':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddPostDialog(
                                        idParent: idDirektori,
                                        idKelas: idKelas,
                                        existingPostId: doc.id,
                                        existingPostTitle: data['nama'],
                                        existingPostDesc: data['deskripsi'],
                                      ),
                                    ),
                                  );
                                  break;
                                case 'delete':
                                  await FirebaseFirestore.instance
                                      .collection('direktori')
                                      .doc(doc.id)
                                      .delete();
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_box_rounded,
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
                  builder: (context) => AddPostDialog(
                    idParent: idDirektori,
                    idKelas: idKelas,
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
                  builder: (context) => AddFolderDialog(
                    idParent: idDirektori,
                    idKelas: idKelas,
                  ),
                ),
              );
            },
            child: const Icon(Icons.create_new_folder),
          )
        ],
      ),
    );
  }
}
