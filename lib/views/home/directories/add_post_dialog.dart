import 'package:flutter/material.dart';
import 'package:studyshare/models/directory/folder.dart';

class AddPostDialog extends StatefulWidget {
  const AddPostDialog({
    super.key,
    this.existingPost,
  });
  final Folder? existingPost;

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  var _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost == null ? 'Buat post' : 'Edit post'),
        actions: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
            ),
            child: Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        children: [
          TextFormField(
            initialValue: widget.existingPost?.name,
            decoration: const InputDecoration(
              icon: Icon(Icons.title),
              label: Text('Judul Postingan'),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: widget.existingPost?.description,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              icon: Icon(Icons.notes),
              label: Text('Deskripsi'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Pilih berkas',
              style: textTheme.titleMedium,
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: 180,
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              border: Border.all(
                color:
                    _isDragging ? colorScheme.primary : colorScheme.onSurface,
                width: _isDragging ? 2 : 1,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text("Pilih FIle"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
