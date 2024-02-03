import 'package:flutter/material.dart';

enum PopupItem {
  edit,
  delete,
}

class DirectoriesPage extends StatelessWidget {
  const DirectoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          Text("Folder"),
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xffcd3676),
                  child: Icon(Icons.folder),
                ),
                trailing: PopupMenuButton<PopupItem>(
                  itemBuilder: (context) => PopupItem.values.map(
                    (item) {
                      return PopupMenuItem<PopupItem>(
                        value: item,
                        child: Text(
                          () {
                            switch (item) {
                              case PopupItem.edit:
                                return 'Edit';
                              case PopupItem.delete:
                                return 'Delete';
                            }
                          }(),
                        ),
                      );
                    },
                  ).toList(),
                  onSelected: (PopupItem selectedItem) {
                    // Handle the selected item here
                    switch (selectedItem) {
                      case PopupItem.edit:
                        // Handle edit action
                        break;
                      case PopupItem.delete:
                        // Handle delete action
                        break;
                    }
                  },
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                title: Text("Pertemuan 1"),
                tileColor: colorScheme.surfaceVariant,
                onTap: () {
                  // Hande tile tap if needed
                },
              ),
            ],
          ),
          Text("Postingan"),
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                title: Text("Perhatian"),
                subtitle: Text("balallalalaaaaaaaa"),
                tileColor: colorScheme.surfaceVariant,
                onTap: () {
                  // Handle tile tap if needed
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
