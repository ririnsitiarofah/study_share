import 'package:flutter/material.dart';
import 'package:studyshare/main.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text("Pengaturan"),
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Tampilan',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: notifier,
                    builder: (_, mode, child) {
                      return ListTile(
                        title: const Text('Tema'),
                        subtitle: Text(switch (mode) {
                          ThemeMode.system => "Sistem",
                          ThemeMode.light => "Terang",
                          ThemeMode.dark => "Gelap",
                        }),
                        leading: const CircleAvatar(
                          child: Icon(Icons.brightness_4),
                        ),
                        trailing: const Icon(Icons.arrow_right),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                title: const Text("Pilih Tema"),
                                children: [
                                  RadioListTile(
                                    title: const Text("Sistem"),
                                    value: ThemeMode.system,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        notifier.value = value;
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    title: const Text("Terang"),
                                    value: ThemeMode.light,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        notifier.value = value;
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    title: const Text("Gelap"),
                                    value: ThemeMode.dark,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        notifier.value = value;
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 64),
          )
        ],
      ),
    );
  }
}
