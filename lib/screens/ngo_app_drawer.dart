import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'donation_screen_ngo.dart';
import 'ngo_edit_profile_screen.dart';
import 'about_us_screen.dart';
import 'event_creation_screen.dart';
import 'welcome_screen.dart';
import 'blood_request_notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NGOAppDrawer extends StatefulWidget {
  const NGOAppDrawer({super.key});

  @override
  State<NGOAppDrawer> createState() => _NGOAppDrawerState();
}

class _NGOAppDrawerState extends State<NGOAppDrawer> {
  String _ngoName = "Loading...";
  String _ngoEmail = "Loading...";
  String? _ngoLogoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNgoDetails();
  }

  /// Fetch NGO details from Supabase using stored ID
  Future<void> _fetchNgoDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ngoId = prefs.getString('ngo_id');

      if (ngoId == null) {
        setState(() {
          _ngoName = "Unknown NGO";
          _ngoEmail = "No Email";
          _ngoLogoUrl = null;
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('ngos')
          .select('ngo_name, email, logo_url')
          .eq('id', ngoId)
          .single();

      if (mounted) {
        setState(() {
          _ngoName = response['ngo_name'] ?? "Unknown NGO";
          _ngoEmail = response['email'] ?? "No Email";
          _ngoLogoUrl = response['logo_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ngoName = "Error loading data";
          _ngoEmail = "";
          _ngoLogoUrl = null;
          _isLoading = false;
        });
      }
      debugPrint("Error fetching NGO details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFAF7F0)),
            currentAccountPicture: ClipOval(
              child: _isLoading
                  ? CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.business,
                          size: 40, color: Colors.black),
                    )
                  : (_ngoLogoUrl != null && _ngoLogoUrl!.isNotEmpty)
                      ? Image.network(
                          _ngoLogoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.business,
                                size: 40, color: Colors.black),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: Image.asset(
                            'assets/ngo_logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
            ),
            accountName: Text(
              _isLoading ? "Loading..." : _ngoName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              _isLoading ? "Loading..." : _ngoEmail,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          DrawerItem(
            icon: Icons.home,
            text: "Home",
            onTap: () => Navigator.pop(context),
          ),
          DrawerItem(
            icon: Icons.receipt_long,
            text: "Donations",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DonationScreen()),
              );
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
                  builder: (context) => const BloodRequestNotificationScreen(),
                ),
              );
            },
          ),
          DrawerItem(
            icon: Icons.event,
            text: "Events",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventCreationScreen(),
                ),
              );
            },
          ),
          DrawerItem(
            icon: Icons.info,
            text: "About Us",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsScreen()),
              );
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
                  builder: (context) => const NGOEditProfileScreen(),
                ),
              );
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
              await Supabase.instance.client.auth.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('ngo_id');

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Public DrawerItem class for reuse
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
