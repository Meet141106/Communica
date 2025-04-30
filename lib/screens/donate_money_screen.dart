// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonateMoneyScreen extends StatefulWidget {
  const DonateMoneyScreen({super.key});

  @override
  _DonateMoneyScreenState createState() => _DonateMoneyScreenState();
}

class _DonateMoneyScreenState extends State<DonateMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _ngoId;

  @override
  void initState() {
    super.initState();
    _fetchNgoId();
  }

  /// Fetch NGO ID from SharedPreferences
  Future<void> _fetchNgoId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ngoId = prefs.getString('ngo_id');
    });
  }

  /// Submit Donation Details to Supabase
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? ngoId = prefs.getString('ngo_id');

        if (ngoId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("NGO ID not found! Please re-login.")),
          );
          return;
        }

        await supabase.from('money_donations').insert({
          'donor_name': _nameController.text,
          'donor_mobile': _mobileController.text,
          'donation_amount': double.parse(_amountController.text),
          'donor_email': _emailController.text,
          'remarks': _remarksController.text,
          'ngo_id': ngoId, // Storing the logged-in NGO ID
          'created_at': DateTime.now().toIso8601String(),
        });

        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation submitted successfully!")),
        );
        Navigator.pop(context); // Navigate back after submission
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      }
    }
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
          "Donate Money",
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Donate Money",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900),
              ),
              const SizedBox(height: 5),
              Text(
                "Please fill the form & submit to make the donation",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900),
              ),
              const SizedBox(height: 20),
              buildTextField("Donor Full Name", Icons.person, _nameController),
              buildTextField("Donor Mobile No", Icons.phone, _mobileController),
              buildTextField("Donation Amount", Icons.money, _amountController,
                  keyboardType: TextInputType.number),
              buildTextField(
                  "Remarks (Optional)", Icons.edit, _remarksController),
              buildTextField("Email", Icons.email, _emailController),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Submit",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, IconData icon, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }
}
