import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/setting/setting_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text("Akun"),
              backgroundColor: colorScheme.background,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SettingPage()));
                  },
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Profil Kamu",
                            style: textTheme.titleMedium,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Semua orang di kelas kamu bakal bisa melihat info ini.",
                            style: textTheme.bodyMedium,
                          ),
                          Divider(
                            height: 8,
                          ),
                          ListTile(
                            title: Text("Nama"),
                            subtitle: Text("Ririn Siti Arofah"),
                            trailing: Icon(Icons.arrow_right),
                            onTap: () {},
                          ),
                          ListTile(
                            title: Text("Email"),
                            subtitle: Text("ririnsitiarofah12@gmail.com"),
                            trailing: Icon(Icons.arrow_right),
                            onTap: () {},
                          ),
                          ListTile(
                            title: const Text('Password'),
                            subtitle: const Text('********'),
                            trailing: const Icon(Icons.arrow_right),
                            onTap: () {},
                          ),
                        ]),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kelas",
                          style: textTheme.titleMedium,
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Data kelas kamu sekarang",
                          style: textTheme.bodyMedium,
                        ),
                        Divider(
                          height: 8,
                        ),
                        ListTile(
                          title: Text("Nama Kelas"),
                          subtitle: Text("PTIK 7 B"),
                          trailing: Icon(Icons.arrow_right),
                          onTap: () {},
                        ),
                        ListTile(
                          title: Text("Kode Kelass"),
                          subtitle: Text("bgdgDahdGRDgd"),
                          trailing: Icon(Icons.qr_code),
                          onTap: () {},
                        ),
                        ListTile(
                          title: const Text('Anggota Kelas'),
                          subtitle: const Text('22 anggota'),
                          trailing: const Icon(Icons.arrow_right),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () {},
                    child: Text('Keluar kelas'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => SignInPage()),
                          (_) => false);
                    },
                    child: Text('Keluar Akun'),
                  ),
                ],
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
