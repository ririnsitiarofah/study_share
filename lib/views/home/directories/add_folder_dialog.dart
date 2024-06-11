import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/core/utils/colors.dart';

class AddFolderDialog extends StatefulWidget {
  const AddFolderDialog({
    super.key,
    this.existingFolderId,
    this.existingFolderName,
    this.existingFolderDesc,
    this.existingFolderColor,
    required this.idParent,
    required this.idKelas,
  });
  final String? idParent;
  final String? idKelas;

  final String? existingFolderId;
  final String? existingFolderName;
  final String? existingFolderDesc;
  final int? existingFolderColor;

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedColor = colorPalettes.first.color;

  @override
  void initState() {
    if (widget.existingFolderId != null) {
      _nameController.text = widget.existingFolderName!;
      _descriptionController.text = widget.existingFolderDesc ?? '';
      _selectedColor = widget.existingFolderColor!;
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingFolderId == null
              ? widget.idKelas != null
                  ? 'Buat folder'
                  : 'Buat personal folder'
              : 'Edit folder',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              try {
                if (!_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Isi semua kolom'),
                    ),
                  );
                  return;
                }

                // EDIT FOLDER
                if (widget.existingFolderId != null) {
                  FirebaseFirestore.instance
                      .collection('direktori')
                      .doc(widget.existingFolderId)
                      .update(
                    {
                      'nama': _nameController.text,
                      'deskripsi': _descriptionController.text.isEmpty
                          ? null
                          : _descriptionController.text,
                      'warna': _selectedColor,
                      'terakhir_dimodifikasi': FieldValue.serverTimestamp(),
                    },
                  );
                  Navigator.pop(context);
                  return;
                }

                // BUAT FOLDER

                final user = FirebaseAuth.instance.currentUser!;
                FirebaseFirestore.instance.collection('direktori').add(
                  {
                    'id_parent': widget.idParent,
                    'id_pemilik': user.uid,
                    'id_kelas': widget.idKelas,
                    'nama': _nameController.text,
                    'deskripsi': _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    'warna': _selectedColor,
                    'tipe': 'folder',
                    'lampiran': null,
                    'tanggal_dibuat': FieldValue.serverTimestamp(),
                    'terakhir_dimodifikasi': FieldValue.serverTimestamp(),
                  },
                );
                Navigator.pop(context);
              } catch (e, stackTrace) {
                log(e.toString(), error: e, stackTrace: stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menyimpan folder"),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Simpan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                icon: Icon(Icons.title),
                label: Text('Nama folder'),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Nama folder tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                icon: Icon(Icons.notes),
                label: Text('Deskripsi'),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Pilih warna',
                style: textTheme.titleMedium,
              ),
            ),
            Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: colorPalettes.map(
                (colorPalette) {
                  return Tooltip(
                    message: colorPalette.name,
                    child: Material(
                      color: Color(colorPalette.color),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedColor = colorPalette.color;
                          });
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: _selectedColor == colorPalette.color
                              ? const Icon(Icons.check)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
