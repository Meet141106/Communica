import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventRegistrationScreen extends StatelessWidget {
  final Map<String, dynamic> event;
  final Map<String, String> ngoLogos;

  const EventRegistrationScreen({
    super.key,
    required this.event,
    required this.ngoLogos,
  });

  @override
  Widget build(BuildContext context) {
    final ngoId = event['ngo_id']?.toString();
    final logoUrl =
        ngoId != null && ngoLogos.containsKey(ngoId) ? ngoLogos[ngoId] : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Event Registration",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventDetails(logoUrl),
            const SizedBox(height: 20),
            Expanded(child: EventRegistrationForm(event: event)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(String? logoUrl) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                ? NetworkImage(logoUrl)
                : const AssetImage("assets/ngo_logo.png") as ImageProvider,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['event_name'] ?? "Event Name",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Date: ${event['date'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Time: ${event['time'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Location: ${event['location'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventRegistrationForm extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventRegistrationForm({super.key, required this.event});

  @override
  _EventRegistrationFormState createState() => _EventRegistrationFormState();
}

class _EventRegistrationFormState extends State<EventRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in first.")),
      );
      return;
    }

    final userId = user.id;
    final eventId = widget.event['id'];

    try {
      // Check for existing registration
      final existing = await _supabase
          .from('event_registrations')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You have already registered for this event.")),
        );
        return;
      }

      // Proceed with new registration
      await _supabase.from('event_registrations').insert({
        'user_id': userId,
        'event_id': eventId,
        'full_name': _nameController.text,
        'mobile_no': _mobileController.text,
        'email': _emailController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful!")),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _buildTextField("Full Name", Icons.person, _nameController),
          const SizedBox(height: 15),
          _buildTextField("Mobile No", Icons.phone, _mobileController,
              TextInputType.phone),
          const SizedBox(height: 15),
          _buildTextField("Email", Icons.email, _emailController,
              TextInputType.emailAddress),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon,
      TextEditingController controller, [TextInputType type = TextInputType.text]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) => value!.isEmpty ? "Please enter $hint" : null,
    );
  }
}
