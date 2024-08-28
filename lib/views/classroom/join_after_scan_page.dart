import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:studyshare/core/utils/notifications_utils.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/home_page.dart';

class JoinAfterScanPage extends StatefulWidget {
  const JoinAfterScanPage({super.key, required this.kodeKelas});

  final String kodeKelas;

  @override
  State<JoinAfterScanPage> createState() => _JoinAfterScanPageState();
}

class _JoinAfterScanPageState extends State<JoinAfterScanPage> {
  final _nimController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar.large(
            title: Text('Satu langkah lagi!'),
          ),
        ],
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tinggal masukin NIM kamu di bawah, buat pengenal aja di kelas kamu~',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nimController,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText: 'NIM kamu gak boleh kosong yah.',
                          ),
                        ]),
                        decoration: const InputDecoration(
                          labelText: 'NIM (Nomor Induk Mahasiswa)',
                          icon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            backgroundColor: colorScheme.primary,
                          ).copyWith(
                            elevation: ButtonStyleButton.allOrNull(0),
                          ),
                          onPressed: () async {
                            try {
                              if (!_formKey.currentState!.validate()) return;

                              final classSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('kelas')
                                  .where('kode_kelas',
                                      isEqualTo: widget.kodeKelas)
                                  .get();

                              if (classSnapshot.docs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Kode kelas kamu enggak valid eyyy."),
                                  ),
                                );
                                return;
                              }

                              final user = FirebaseAuth.instance.currentUser!;
                              final doc = classSnapshot.docs.first;

                              final classMemberByIdSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('member_kelas')
                                      .where('id_user', isEqualTo: user.uid)
                                      .where('id_kelas', isEqualTo: doc.id)
                                      .get();

                              if (classMemberByIdSnapshot.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Kamu sudah bergabung di kelas ini."),
                                  ),
                                );
                                return;
                              }

                              final classMemberByNimSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('member_kelas')
                                      .where('nim',
                                          isEqualTo: _nimController.text)
                                      .where('id_kelas', isEqualTo: doc.id)
                                      .get();

                              if (classMemberByNimSnapshot.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "NIM kamu sudah terdaftar di kelas ini."),
                                  ),
                                );
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection('member_kelas')
                                  .add({
                                'id_user': user.uid,
                                'id_kelas': doc.id,
                                'nim': _nimController.text,
                                'nama': user.displayName,
                                'nama_kelas': doc['nama'],
                                'role': 'anggota',
                              });

                              final roomsSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('room_chat')
                                  .where('metadata.id_kelas', isEqualTo: doc.id)
                                  .get();

                              final room = await processRoomDocument(
                                roomsSnapshot.docs.first,
                                FirebaseAuth.instance.currentUser!,
                                FirebaseFirestore.instance,
                                'user',
                              );

                              final metadata = room.metadata ?? {};
                              final updatedRoom = room.copyWith(
                                metadata: {
                                  ...metadata,
                                  'users': {
                                    ...metadata['users'] ?? {},
                                    user.uid: user.displayName,
                                  },
                                },
                                users: [
                                  ...room.users,
                                  types.User(
                                    id: user.uid,
                                    firstName: user.displayName!,
                                    role: types.Role.user,
                                  ),
                                ],
                              );

                              FirebaseChatCore.instance.updateRoom(updatedRoom);
                              await FirebaseMessaging.instance
                                  .subscribeToTopic('chat:${doc.id}');

                              await saveNotifications(context);

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HomePage(initialIndex: 2),
                                ),
                                (route) => false,
                              );
                            } catch (e, stackTrace) {
                              log(e.toString(),
                                  error: e, stackTrace: stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Gagal bergabung ke kelas. Silakan coba lagi."),
                                ),
                              );
                            }
                          },
                          child: const Text('Join kelas'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Salah akun?'),
                          TextButton(
                            onPressed: () {
                              FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Masuk lagi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
