import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyshare/views/core/helpers/formatters.dart';
import 'package:studyshare/views/home/directories/add_post_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.idPost});

  final String idPost;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("direktori")
            .doc(widget.idPost)
            .get(),
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

          final lampirans = data['lampiran'] as Map<String, dynamic>;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Text(data['nama']),
                actions: [
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
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => AddPostDialog(
                                idParent: data['id_parent'],
                                idKelas: data['id_kelas'],
                                existingPostDesc: data['deskripsi'],
                                existingPostId: doc.id,
                                existingPostTitle: data['nama'],
                              ),
                            ),
                          );
                          if (result) {
                            setState(() {});
                          }
                          break;
                        case 'delete':
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Hapus Postingan'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus postingan ini?'),
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
                                      style:
                                          TextStyle(color: colorScheme.error),
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
                            Navigator.pop(context);
                          }
                          break;
                      }
                    },
                  ),
                ],
              )
            ],
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (data['deskripsi'] != null) ...[
                  LinkifyText(
                    data['deskripsi'],
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    linkTypes: LinkType.values,
                    linkStyle: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                    onTap: (link) async {
                      try {
                        context.loaderOverlay.show();

                        switch (link.type) {
                          case LinkType.url:
                            if (link.value!.startsWith('http') ||
                                link.value!.startsWith('https')) {
                              await launchUrlString(link.value!);
                            } else {
                              await launchUrl(Uri.https(link.value!));
                            }
                          case LinkType.email:
                            await launchUrlString('mailto:${link.value!}');
                          case LinkType.hashTag:
                            break;
                          case LinkType.userTag:
                            break;
                          case LinkType.phone:
                            await launchUrlString('tel:${link.value!}');
                          case null:
                          // TODO: Handle this case.
                        }
                      } catch (e) {
                        log(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Gagal membuka link, silahkan coba lagi!"),
                          ),
                        );
                      } finally {
                        context.loaderOverlay.hide();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                ...lampirans.entries.map(
                  (entry) {
                    final key = entry.key;
                    final value = entry.value;

                    return Card(
                      child: ListTile(
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        leading: Icon(
                          formatFileTypeIcon(value['tipe']).icon,
                          color: formatFileTypeColor(value['tipe']),
                        ),
                        title: Text(value['nama']),
                        subtitle: Text(_formatSize(value['ukuran'])),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => _handleLampiranTap(
                          context: context,
                          id: key,
                          extension: value['tipe'],
                          url: value['url'],
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  () {
                    if (data['tanggal_dibuat'] !=
                        data['terakhir_dimodifikasi']) {
                      return '${_formatDate(data['tanggal_dibuat'])} • diubah ${_formatSimpleDate(data['tanggal_dibuat'], data['terakhir_dimodifikasi'])}';
                    }
                    return _formatDate(data['tanggal_dibuat']);
                  }(),
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
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

  String _formatSize(int? size) {
    if (size == null) {
      return "0 B";
    } else if (size < 1024) {
      return "$size B";
    } else if (size < 1024 * 1024) {
      return "${(size / 1024).toStringAsFixed(2)} KB";
    } else if (size < 1024 * 1024 * 1024) {
      return "${(size / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      return "${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    }
  }

  String _formatDate(Timestamp date) {
    return DateFormat('HH:mm • d MMM y').format(date.toDate());
  }

  String _formatSimpleDate(Timestamp created, Timestamp updated) {
    final createdDate = created.toDate();
    final updatedDate = updated.toDate();
    if (DateTime(createdDate.year, createdDate.month, createdDate.day) ==
        DateTime(updatedDate.year, updatedDate.month, updatedDate.day)) {
      return DateFormat('HH:mm').format(createdDate);
    }
    return DateFormat('HH:mm • d MMM y').format(updated.toDate());
  }
}
