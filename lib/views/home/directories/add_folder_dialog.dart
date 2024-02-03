import 'package:studyshare/models/directory/folder.dart';
import 'package:studyshare/views/core/utils/colors.dart';
import 'package:flutter/material.dart';

class AddFolderDialog extends StatelessWidget {
  const AddFolderDialog({
    super.key,
    this.existingFolder,
  });
  final Folder? existingFolder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
        appBar: AppBar(
          title: Text(existingFolder == null ? 'Buat folder' : 'Edit folder'),
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
              initialValue: existingFolder?.name,
              decoration: const InputDecoration(
                icon: Icon(Icons.title),
                label: Text('Nama folder'),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: existingFolder?.description,
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
                        onTap: () {},
                        child: SizedBox(
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ));
  }
}
