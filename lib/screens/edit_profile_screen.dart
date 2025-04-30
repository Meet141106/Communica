import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    print("Fetching data for User ID: ${user.id}");

    // Fetch Name from Supabase
    final response = await supabase
        .from('user_signup')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();

    print("Supabase Response: $response");

    if (response != null && response['full_name'] != null) {
      setState(() {
        nameController.text = response['full_name'];
      });
    } else {
      print("No full_name found for user");
    }

    // Fetch Email from Supabase Auth (No DB relation)
    setState(() {
      emailController.text = user.email ?? "No Email Found";
      passwordController.text = "**********"; // Always masked
      dobController.text = "23/05/1995"; // Editable
      regionController.text = "Nigeria"; // Editable
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image (Fixed)
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile.png"), // Fixed image
              backgroundColor: Colors.transparent, // Remove default pink bg
            ),
            const SizedBox(height: 20),
            _buildEditableTextField("Name", nameController),
            _buildDisabledTextField("Email", emailController),
            _buildDisabledTextField("Password", passwordController),
           
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle save changes
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade900,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save changes",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Editable Fields (Name, DOB, Region)
  Widget _buildEditableTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ Non-Editable Fields (Email, Password)
  Widget _buildDisabledTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            readOnly: true,
            enabled: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
