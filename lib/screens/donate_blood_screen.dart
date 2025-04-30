// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonateBloodScreen extends StatefulWidget {
  const DonateBloodScreen({super.key});

  @override
  _DonateBloodScreenState createState() => _DonateBloodScreenState();
}

class _DonateBloodScreenState extends State<DonateBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedBloodGroup;
  String? _ngoId;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-"
  ];

  @override
  void initState() {
    super.initState();
    _fetchNgoId();
  }

  /// Fetch NGO ID from SharedPreferences
  Future<void> _fetchNgoId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ngoId = prefs.getString('ngo_id'); // Retrieve NGO ID
    });
  }

  /// Submit Blood Donation Request
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? ngoId =
            prefs.getString('ngo_id'); // Retrieve stored NGO ID

        if (ngoId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("NGO ID not found! Please re-login.")),
          );
          return;
        }

        await Supabase.instance.client.from('blood_donations').insert({
          'donor_name': _nameController.text,
          'donor_mobile': _mobileController.text,
          "donor_age": int.parse(_ageController.text),
          'blood_group': _selectedBloodGroup,
          'donor_city': _cityController.text, // Fixed column name
          'remarks': _remarksController.text,
          'ngo_id': ngoId, // Storing the logged-in NGO ID
          'created_at': DateTime.now().toIso8601String(),
        });

        // Show success message & navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blood donation request submitted!")),
        );
        Navigator.pop(context);
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
          "Donate Blood",
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
                "Donate Blood",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900),
              ),
              const SizedBox(height: 5),
              const Text(
                "Please fill the form & submit to make the donation",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              buildTextField("Donor Full Name", _nameController, Icons.person),
              buildTextField("Donor Mobile No", _mobileController, Icons.phone,
                  keyboardType: TextInputType.phone),
              buildTextField("Age", _ageController, Icons.calendar_today,
                  keyboardType: TextInputType.number),
              buildTextField(
                  "Remarks (Optional)", _remarksController, Icons.edit),
              buildTextField("City", _cityController, Icons.location_city),
              buildDropdownField(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Submit",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedBloodGroup,
        items: bloodGroups.map((String group) {
          return DropdownMenuItem<String>(
            value: group,
            child: Text(group),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedBloodGroup = newValue;
          });
        },
        validator: (value) =>
            value == null ? "Please select a blood group" : null,
        decoration: InputDecoration(
          labelText: "Blood Group",
          prefixIcon: const Icon(Icons.bloodtype, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
