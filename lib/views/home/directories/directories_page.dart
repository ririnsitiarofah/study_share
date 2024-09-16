import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyshare/views/core/helpers/formatters.dart';
import 'package:studyshare/views/home/directories/add_folder_dialog.dart';
import 'package:studyshare/views/home/directories/add_post_dialog.dart';
import 'package:studyshare/views/home/directories/post_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DirectoriesPage extends StatelessWidget {
  const DirectoriesPage({
    super.key,
    required this.isKelas,
    required this.idKelas,
    required this.namaKelas,
    required this.idDirektori,
    required this.namaDirektori,
    required this.tabController,
  });

  final bool isKelas;
  final String idKelas;
  final String namaKelas;
  final String? idDirektori;
  final String? namaDirektori;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final folderQuery = isKelas
        ? FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'folder')
            .where('id_parent',
                isEqualTo: idDirektori, isNull: idDirektori == null)
            .where('id_kelas', isEqualTo: idKelas)
            .orderBy('nama')
        : FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'folder')
            .where('id_parent',
                isEqualTo: idDirektori, isNull: idDirektori == null)
            .where('id_kelas', isNull: true)
            .where('id_pemilik',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('nama');

    final postQuery = isKelas
        ? FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'postingan')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isEqualTo: idKelas)
            .orderBy('tanggal_dibuat', descending: true)
        : FirebaseFirestore.instance
            .collection('direktori')
            .where('tipe', isEqualTo: 'postingan')
            .where('id_parent', isEqualTo: idDirektori)
            .where('id_kelas', isNull: true)
            .where('id_pemilik',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('tanggal_dibuat', descending: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Text(
                "Folder",
                style: textTheme.titleSmall,
              ),
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(data['warna'] ?? 0xffcd3676),
                        child: const Icon(Icons.folder),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Hapus Folder'),
                                    content: const Text(
                                        'Apakah Anda yakin ingin menghapus folder ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: Text(
                                          'Hapus',
                                          style: TextStyle(
                                              color: colorScheme.error),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete == true) {
                                await FirebaseFirestore.instance
                                    .collection('direktori')
                                    .doc(doc.id)
                                    .delete();
                              }
                              break;
                          }
                        },
                      ),
                      title: Text(data['nama']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(data['nama']),
                              ),
                              body: DirectoriesPage(
                                idKelas: idKelas,
                                namaKelas: namaKelas,
                                idDirektori: doc.id,
                                namaDirektori: data['nama'],
                                tabController: tabController,
                                isKelas: isKelas,
                              ),
                              floatingActionButton: SpeedDial(
                                heroTag: 'fab',
                                icon: Icons.add,
                                label: !isKelas ? const Text("Personal") : null,
                                shape: Theme.of(context)
                                        .floatingActionButtonTheme
                                        .shape ??
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
                                            idParent: doc.id,
                                            idKelas: isKelas ? idKelas : null,
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
                                            idParent: doc.id,
                                            idKelas: isKelas ? idKelas : null,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.create_new_folder),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Text(
                "Postingan",
                style: textTheme.titleSmall,
              ),
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

                  final lampirans = data['lampiran'] as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(
                              idPost: doc.id,
                            ),
                          ),
                        );
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                                  Text(
                                    data['nama'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium,
                                  ),
                                  if (data['terakhir_dimodifikasi'] != null)
                                    Text(
                                      _formatDate(
                                          data['terakhir_dimodifikasi']),
                                      style: textTheme.labelSmall!.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (data['deskripsi'] != null &&
                                      (data['deskripsi'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    LinkifyText(
                                      data['deskripsi'],
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis,
                                      linkTypes: LinkType.values,
                                      linkStyle: TextStyle(
                                        color: colorScheme.primary,
                                      ),
                                      onTap: (link) async {
                                        try {
                                          context.loaderOverlay.show();

                                          switch (link.type) {
                                            case LinkType.url:
                                              if (link.value!
                                                      .startsWith('http') ||
                                                  link.value!
                                                      .startsWith('https')) {
                                                await launchUrlString(
                                                    link.value!);
                                              } else {
                                                await launchUrl(
                                                    Uri.https(link.value!));
                                              }
                                            case LinkType.email:
                                              await launchUrlString(
                                                  'mailto:${link.value!}');
                                            case LinkType.hashTag:
                                              break;
                                            case LinkType.userTag:
                                              break;
                                            case LinkType.phone:
                                              await launchUrlString(
                                                  'tel:${link.value!}');
                                            case null:
                                            // TODO: Handle this case.
                                          }
                                        } catch (e) {
                                          log(e.toString());
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Gagal membuka link, silahkan coba lagi!"),
                                            ),
                                          );
                                        } finally {
                                          context.loaderOverlay.hide();
                                        }
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                        lampirans.entries.take(2).map((entry) {
                                      return ActionChip(
                                        label: Text(entry.value['nama']),
                                        avatar: Icon(
                                          formatFileTypeIcon(
                                                  entry.value['tipe'])
                                              .icon,
                                          color: formatFileTypeColor(
                                              entry.value['tipe']),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                        elevation: 0,
                                        pressElevation: 0,
                                        surfaceTintColor: Colors.transparent,
                                        onPressed: () => _handleLampiranTap(
                                          context: context,
                                          id: entry.key,
                                          extension: entry.value['tipe'],
                                          url: entry.value['url'],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (lampirans.length > 2) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '+ ${lampirans.length - 2} lampiran lainnya',
                                      style: textTheme.labelMedium,
                                    ),
                                  ],
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
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Hapus Folder'),
                                        content: const Text(
                                            'Apakah Anda yakin ingin menghapus folder ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: Text(
                                              'Hapus',
                                              style: TextStyle(
                                                  color: colorScheme.error),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

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
                    ),
                  );
                },
              );
            },
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 48),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLampiranTap({
    required BuildContext context,
    required String id,
    required String extension,
    required String url,
  }) async {
    try {
      context.loaderOverlay.show();

      final documentsDir = (await getApplicationDocumentsDirectory()).path;
      final localPath = '$documentsDir/$id.$extension';

      if (File(localPath).existsSync()) {
        await OpenFilex.open(localPath);
        return;
      }

      final client = http.Client();
      final request = await client.get(Uri.parse(url));
      final bytes = request.bodyBytes;

      final file = File(localPath);
      await file.writeAsBytes(bytes);

      await OpenFilex.open(localPath);
    } catch (e, stackTrace) {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengunduh lampiran. Silakan coba lagi."),
        ),
      );
    } finally {
      context.loaderOverlay.hide();
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.isAfter(now.subtract(const Duration(days: 2)))) {
      return timeago.format(date);
    }

    return DateFormat('d MMM yyyy HH:mm').format(date);
  }
}
