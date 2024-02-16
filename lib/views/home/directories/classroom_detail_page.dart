import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class ClassroomDetailPage extends StatelessWidget {
  const ClassroomDetailPage({super.key, required this.idKelas});

  final String idKelas;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder(
        future:
            FirebaseFirestore.instance.collection("kelas").doc(idKelas).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong! ${snapshot.error}'),
            );
          }

          final doc = snapshot.data!;
          final data = doc.data()!;

          final user = FirebaseAuth.instance.currentUser!;

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(data['nama']),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Deskripsi'),
                        subtitle:
                            Text(data['deskripsi'] ?? 'Tidak ada deskripsi'),
                      ),
                      ListTile(
                        title: const Text('Kode Kelas'),
                        subtitle: Text(data['kode_kelas']),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('QR Code'),
                                  content: Image.network(
                                    'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${data['kode_kelas']}',
                                  ),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: data['kode_kelas'],
                                          ),
                                        );
                                      },
                                      child: const Text('Salin kode'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        title: const Text('Keluar kelas'),
                        leading: Icon(Icons.logout, color: colorScheme.error),
                        textColor: colorScheme.error,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Keluar kelas'),
                                content: const Text(
                                    'Apakah kamu yakin ingin keluar kelas ini?'),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('member_kelas')
                                          .where('id_kelas', isEqualTo: idKelas)
                                          .where('id_user', isEqualTo: user.uid)
                                          .get()
                                          .then((snapshot) {
                                        for (final doc in snapshot.docs) {
                                          doc.reference.delete();
                                        }
                                      });

                                      final roomsSnapshot =
                                          await FirebaseFirestore.instance
                                              .collection('room_chat')
                                              .where('metadata.id_kelas',
                                                  isEqualTo: doc.id)
                                              .get();

                                      final room = await processRoomDocument(
                                        roomsSnapshot.docs.first,
                                        FirebaseAuth.instance.currentUser!,
                                        FirebaseFirestore.instance,
                                        'user',
                                      );

                                      final updatedRoom = room.copyWith(
                                        users: room.users
                                          ..removeWhere((chatUser) =>
                                              chatUser.id == user.uid),
                                      );

                                      FirebaseChatCore.instance
                                          .updateRoom(updatedRoom);

                                      Navigator.popUntil(
                                          context, (route) => route.isFirst);
                                    },
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Anggota'),
                ),
              ),
              FirestoreQueryBuilder(
                query: FirebaseFirestore.instance
                    .collection('member_kelas')
                    .where('id_kelas', isEqualTo: idKelas),
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
                    return const SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group,
                            size: 48,
                            // color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Tidak ada member di kelas ini",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: snapshot.docs.length,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore &&
                          index + 1 == snapshot.docs.length) {
                        snapshot.fetchMore();
                      }

                      final doc = snapshot.docs[index];
                      final data = doc.data();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(data['color'] ?? 0xffcd3676),
                            child: const Icon(Icons.person),
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (data['id_user'] != user.uid ||
                                  (data['id_user'] == user.uid &&
                                      (data['role'] == 'admin' ||
                                          data['role'] == 'pemilik')))
                                const PopupMenuItem(
                                  value: 'kick',
                                  child: Text('Kick'),
                                ),
                            ],
                            onSelected: (selectedItem) async {
                              switch (selectedItem) {
                                case 'kick':
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
                          title: Text(data['nama'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}
