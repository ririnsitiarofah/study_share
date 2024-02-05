import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/classroom/create_classroom.dart';
import 'package:studyshare/views/classroom/scan_page.dart';
import 'package:studyshare/views/home/home_page.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _classCodeController = TextEditingController();
  final _nimController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _classCodeController.dispose();
    _nimController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text("Ayo join!"),
              backgroundColor: colorScheme.background,
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                      const Text(
                        'Masukin kode kelas kamu di bawah (psst, tanyain kodenya ke temen kamu)',
                      ),
                      TextFormField(
                        controller: _classCodeController,
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.minLength(
                              7,
                              errorText: "Kode kelas kamu enggak valid eyyy.",
                            ),
                            FormBuilderValidators.maxLength(
                              14,
                              errorText: "Kode kelas kamu enggak valid eyyy.",
                            ),
                          ],
                        ),
                        decoration: const InputDecoration(
                          labelText: "Kode Kelas",
                          icon: Icon(Icons.pin_rounded),
                        ),
                      ),
                      TextFormField(
                        controller: _nimController,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: 'NIM kamu gak boleh kosong yah.',
                            ),
                          ],
                        ),
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
                                      isEqualTo: _classCodeController.text)
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

                              final classMemberSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('member_kelas')
                                      .where('id_user', isEqualTo: user.uid)
                                      .where('id_kelas', isEqualTo: doc.id)
                                      .get();

                              if (classMemberSnapshot.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Kamu sudah bergabung di kelas ini."),
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

                              room.users.add(
                                types.User(
                                  id: user.uid,
                                  firstName: user.displayName!,
                                  role: types.Role.user,
                                ),
                              );

                              FirebaseChatCore.instance.updateRoom(room);

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
                          child: const Text('Join Kelas'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateClassroomPage()));
                          },
                          child: const Text('Buat Kelas'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.center,
                        child: Text('Kamu males ngetik?'),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: Theme.of(context).textTheme.headline6,
                          ).copyWith(
                            elevation: ButtonStyleButton.allOrNull(0),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ScanPage()));
                          },
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 28,
                          ),
                          label: const Text('Scan QR'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Salah akun?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInPage()));
                            },
                            child: const Text('Masuk lagi'),
                          ),
                        ],
                      )
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
