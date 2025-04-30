import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'donation_screen.dart';
import 'edit_profile_screen.dart';
import 'about_us_screen.dart';
import 'event_screen.dart';
import 'welcome_screen.dart';
import 'blood_request_notification_screen.dart'; // New import

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final supabase = Supabase.instance.client;
  String? fullName;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await supabase
            .from('user_signup')
            .select('full_name, email')
            .eq('id', user.id)
            .single();

        setState(() {
          fullName = response['full_name'];
          email = response['email'];
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFAF7F0)),
            accountName: Text(
              isLoading ? "Loading..." : (fullName ?? "User"),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            accountEmail: Text(
              isLoading ? "" : (email ?? ""),
              style: const TextStyle(color: Colors.black54),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 40, color: Colors.black),
            ),
          ),
          DrawerItem(
              icon: Icons.home,
              text: "Home",
              onTap: () => Navigator.pop(context)),
          DrawerItem(
            icon: Icons.receipt_long,
            text: "Donations",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DonationScreen()));
            },
          ),
          DrawerItem(
            icon: Icons.local_hospital,
            text: "Blood Requests",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const BloodRequestNotificationScreen()));
            },
          ),
          DrawerItem(
            icon: Icons.event,
            text: "Events",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const EventScreen()));
            },
          ),
          DrawerItem(
            icon: Icons.info,
            text: "About Us",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AboutUsScreen()));
            },
          ),
          DrawerItem(
            icon: Icons.person,
            text: "Profile",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          DrawerItem(
            icon: Icons.logout,
            text: "Log Out",
            color: Colors.brown.shade900,
            isBold: true,
            onTap: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool isBold;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black54),
      title: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
