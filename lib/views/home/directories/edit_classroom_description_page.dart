import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditClassroomDescPage extends StatefulWidget {
  const EditClassroomDescPage({
    super.key,
    required this.idKelas,
    required this.descKelas,
  });

  final String idKelas;
  final String descKelas;

  @override
  State<EditClassroomDescPage> createState() => _EditClassroomDescPageState();
}

class _EditClassroomDescPageState extends State<EditClassroomDescPage> {
  late final TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _descController = TextEditingController(text: widget.descKelas);
    super.initState();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Deskripsi Kelas'),
        actions: [
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await FirebaseFirestore.instance
                    .collection('kelas')
                    .doc(widget.idKelas)
                    .update({'deskripsi': _descController.text});
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            TextFormField(
              controller: _descController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi kelas tidak boleh kosong';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Deskripsi Kelas',
                hintText: 'Masukkan deskripsi Kelas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
