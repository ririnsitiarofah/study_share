import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.idKelas,
    required this.namaKelas,
  });

  final String idKelas;
  final String namaKelas;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  types.Room? _room;

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, _room!.id);
  }

  void _handleSendPressed(types.PartialText message) {
    FirebaseChatCore.instance.sendMessage(
      message,
      _room!.id,
    );
  }

  Future<void> _init() async {
    try {
      if (_room != null) return;

      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('room_chat')
          .where('metadata.id_kelas', isEqualTo: widget.idKelas)
          .get();

      if (roomsSnapshot.docs.isNotEmpty) {
        _room = await processRoomDocument(
          roomsSnapshot.docs.first,
          FirebaseAuth.instance.currentUser!,
          FirebaseFirestore.instance,
          'user',
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('member_kelas')
          .where('id_kelas', isEqualTo: widget.idKelas)
          .get();

      final docs = snapshot.docs;

      _room = await FirebaseChatCore.instance.createGroupRoom(
        name: widget.namaKelas,
        metadata: {
          'id_kelas': widget.idKelas,
        },
        users: docs.map((doc) {
          final data = doc.data();

          return types.User(
            id: data['id_user'],
            firstName: data['nama'],
            role: switch (data['role']) {
              'pemilik' => types.Role.admin,
              'admin' => types.Role.agent,
              _ => types.Role.user,
            },
          );
        }).toList(),
      );
    } catch (e, stackTrace) {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal membuat ruang chat. Silakan coba lagi."),
        ),
      );
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder(
      future: _init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong! ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        return StreamBuilder<types.Room>(
          initialData: _room,
          stream: FirebaseChatCore.instance.room(_room!.id),
          builder: (context, snapshot) {
            return StreamBuilder<List<types.Message>>(
              initialData: const [],
              stream: FirebaseChatCore.instance.messages(snapshot.data!),
              builder: (context, snapshot) {
                return Chat(
                  showUserNames: true,
                  showUserAvatars: true,
                  nameBuilder: (user) => Text(user.firstName ?? 'Gak da nama'),
                  theme: DefaultChatTheme(
                    backgroundColor: colorScheme.background,
                    inputElevation: 8,
                    inputBorderRadius:
                        const BorderRadius.all(Radius.circular(36)),
                    inputPadding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                    inputMargin: const EdgeInsets.all(8),
                    inputBackgroundColor: colorScheme.surface,
                    inputSurfaceTintColor: colorScheme.surfaceTint,
                    primaryColor: colorScheme.primary,
                    secondaryColor: colorScheme.secondary,
                    errorColor: colorScheme.error,
                    sendButtonIcon: const Icon(Icons.send),
                    sendButtonMargin: EdgeInsets.zero,
                    messageInsetsVertical: 8,
                  ),
                  emptyState: snapshot.connectionState == ConnectionState.active
                      ? Center(
                          child: Text(
                            'Belum ada pesan. Mulai chat sekarang!',
                            style: TextStyle(
                              color: colorScheme.onBackground,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  inputOptions: const InputOptions(
                    sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  ),
                  messages: snapshot.data ?? [],
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  user: types.User(
                    id: FirebaseAuth.instance.currentUser!.uid,
                    firstName: FirebaseAuth.instance.currentUser!.displayName!,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
