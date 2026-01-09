import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/chat_teacher_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).user;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth?.firstName ?? auth?.username ?? 'Guest'),
              accountEmail: Text(auth?.email ?? ''),
              currentAccountPicture: CircleAvatar(child: Text((auth?.firstName ?? 'N').substring(0, 1))),
            ),
            ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Profile'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileInfoScreen()))),
            ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: () {}),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help'), onTap: () {}),
            ListTile(leading: const Icon(Icons.policy), title: const Text('Terms & Policies'), onTap: () {}),
            const Divider(),
            ListTile(leading: const Icon(Icons.supervisor_account), title: const Text('Teacher Requests (Demo)'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatTeacherScreen()))),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                // call logout without awaiting to avoid using BuildContext after an async gap
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
