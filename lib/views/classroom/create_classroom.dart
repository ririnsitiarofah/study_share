import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shortid/shortid.dart';
import 'package:studyshare/views/home/home_page.dart';

class CreateClassroomPage extends StatefulWidget {
  const CreateClassroomPage({super.key});

  @override
  State<CreateClassroomPage> createState() => _CreateClassroomPageState();
}

class _CreateClassroomPageState extends State<CreateClassroomPage> {
  final _classNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nimController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text("Ayo buat kelas!"),
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
                        "Yuk buat kelas buat kamu sama temen kamu! Kalo bukan kamu siapa lagi, ya kan?",
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _classNameController,
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama kelas',
                          icon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.text,
                        validator: FormBuilderValidators.compose([]),
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi kelas',
                          icon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Sekalian lengkapin data kamu yuk!'),
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

                              final docRef = await FirebaseFirestore.instance
                                  .collection('kelas')
                                  .add({
                                'nama': _classNameController.text,
                                'deskripsi': _descriptionController.text,
                                'kode_kelas': shortid.generate(),
                              });

                              final user = FirebaseAuth.instance.currentUser!;

                              await FirebaseFirestore.instance
                                  .collection('member_kelas')
                                  .add({
                                'id_user': user.uid,
                                'id_kelas': docRef.id,
                                'nim': _nimController.text,
                                'nama': user.displayName,
                                'nama_kelas': _classNameController.text,
                                'role': 'pemilik',
                              });

                              await FirebaseChatCore.instance.createGroupRoom(
                                name: _classNameController.text,
                                metadata: {
                                  'id_kelas': docRef.id,
                                },
                                users: [
                                  types.User(
                                    id: user.uid,
                                    firstName: user.displayName!,
                                    role: types.Role.admin,
                                  ),
                                ],
                              );
                              try {
                                await FirebaseMessaging.instance
                                    .subscribeToTopic('chat-${docRef.id}');
                              } catch (e, s) {
                                log(e.toString(), error: e, stackTrace: s);
                              }

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
                                      "Gagal membuat kelas. Silakan coba lagi."),
                                ),
                              );
                            }
                          },
                          child: const Text('Buat kelas'),
                        ),
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
