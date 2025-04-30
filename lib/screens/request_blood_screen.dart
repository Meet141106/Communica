import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  _RequestBloodScreenState createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedBloodGroup;
  String? _ngoId; // NGO ID fetched from SharedPreferences
  String? _selectedUrgency; // New urgency field

  final List<String> _bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-"
  ];
  final List<String> _urgencies = ["Normal", "Urgent"]; // Urgency options

  @override
  void initState() {
    super.initState();
    _fetchNGOId(); // Fetch NGO ID when screen loads
  }

  // Fetch NGO ID from SharedPreferences
  Future<void> _fetchNGOId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ngoId = prefs.getString("ngo_id") ?? "Unknown NGO";
    });
  }

  // Store blood request in Supabase
  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Supabase.instance.client.from('blood_request').insert({
          "patient_name": _nameController.text,
          "mobile_number": _mobileController.text,
          "remarks": _remarksController.text,
          "address": _addressController.text,
          "blood_group": _selectedBloodGroup,
          "ngo_id": _ngoId,
          "request_time": DateTime.now().toIso8601String(),
          "urgency": _selectedUrgency, // Add urgency to insertion
        });

        // Successfully inserted, show a success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blood request submitted!")),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E5902)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Request Blood",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5902),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Urgent Blood Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5902),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Please fill the form & submit to request blood",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // **Patient Name**
                _buildTextField(
                  controller: _nameController,
                  hintText: "Patient Full Name",
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value!.isEmpty ? "Please enter full name" : null,
                ),

                // **Mobile Number**
                _buildTextField(
                  controller: _mobileController,
                  hintText: "Mobile No",
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return "Please enter mobile number";
                    if (value.length < 10) return "Enter a valid mobile number";
                    return null;
                  },
                ),

                // **Remarks (Optional)**
                _buildTextField(
                  controller: _remarksController,
                  hintText: "Remarks (Optional)",
                  icon: Icons.edit_note_outlined,
                ),

                // **Address**
                _buildTextField(
                  controller: _addressController,
                  hintText: "Address",
                  icon: Icons.location_on_outlined,
                  validator: (value) =>
                      value!.isEmpty ? "Please enter address" : null,
                ),

                // **Blood Group Dropdown**
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Blood Group",
                    ),
                    value: _selectedBloodGroup,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _bloodGroups.map((String group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodGroup = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Please select a blood group" : null,
                  ),
                ),

                // **Urgency Dropdown**
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Urgency",
                    ),
                    value: _selectedUrgency,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _urgencies.map((String urgency) {
                      return DropdownMenuItem(
                        value: urgency,
                        child: Text(urgency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUrgency = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Please select urgency" : null,
                  ),
                ),

                const SizedBox(height: 25),

                // **Submit Button**
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5902),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitRequest,
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // **Reusable TextField Widget**
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black45),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
