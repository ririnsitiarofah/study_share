import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("Beranda"),
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Deadline Tugas",
                      style: TextTheme.titleMedium,
                    ),
                  ),
                  const Divider(indent: 8, endIndent: 8, height: 0),
                  const ListTile(
                    title: Text("Study Literatur"),
                    subtitle: Text("23:59 pm, 17 November 2023"),
                    leading: CircleAvatar(child: Icon(Icons.article_rounded)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
