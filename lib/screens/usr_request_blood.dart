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
  String? _selectedPriority;
  String? _selectedNgoId;
  String? _ngoId;
  bool _isNgo = false;
  bool _isLoading = false;

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
  final List<String> _priorities = ["Normal", "Urgent"];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _fetchNGOId();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchNGOId() async {
    final prefs = await SharedPreferences.getInstance();
    String? ngoId = prefs.getString("ngo_id");
    bool isNgo = prefs.getBool("is_ngo") ?? false;

    if (ngoId == null && isNgo) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final response = await Supabase.instance.client
              .from('ngos')
              .select('id')
              .eq('user_id', user.id)
              .single();
          ngoId = response['id']?.toString();
          if (ngoId != null) {
            await prefs.setString("ngo_id", ngoId);
          }
        } catch (e) {
          print("Error fetching NGO ID: $e");
        }
      }
    }

    setState(() {
      _ngoId = ngoId;
      _isNgo = isNgo;
      if (isNgo) _selectedNgoId = ngoId;
    });
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await Supabase.instance.client.from('user_requestblood').insert({
          "user_id": user.id,
          "ngo_id": _selectedNgoId ?? _ngoId ?? "Unknown NGO",
          "patient_name": _nameController.text,
          "mobile_number": _mobileController.text,
          "remarks": _remarksController.text,
          "address": _addressController.text,
          "blood_group": _selectedBloodGroup,
          "priority": _selectedPriority,
          "request_time": DateTime.now().toIso8601String(),
        });

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
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '',
        ),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        icon: const Icon(Icons.keyboard_arrow_down),
        hint: Text(hint),
      ),
    );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        hintText: "Patient Full Name",
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value!.isEmpty ? "Please enter full name" : null,
                      ),
                      _buildTextField(
                        controller: _mobileController,
                        hintText: "Mobile No",
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) return "Enter mobile number";
                          if (value.length < 10) return "Invalid number";
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _remarksController,
                        hintText: "Remarks (Optional)",
                        icon: Icons.edit_note_outlined,
                      ),
                      _buildTextField(
                        controller: _addressController,
                        hintText: "Address",
                        icon: Icons.location_on_outlined,
                        validator: (value) =>
                            value!.isEmpty ? "Please enter address" : null,
                      ),
                      const SizedBox(height: 15),
                      _buildDropdown(
                        hint: "Blood Group",
                        value: _selectedBloodGroup,
                        items: _bloodGroups
                            .map((group) => DropdownMenuItem<String>(
                                  value: group,
                                  child: Text(group),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedBloodGroup = val;
                        }),
                        validator: (val) =>
                            val == null ? "Please select a blood group" : null,
                      ),
                      const SizedBox(height: 15),
                      _buildDropdown(
                        hint: "Request Priority",
                        value: _selectedPriority,
                        items: _priorities
                            .map((priority) => DropdownMenuItem<String>(
                                  value: priority,
                                  child: Text(priority),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedPriority = val;
                        }),
                        validator: (val) =>
                            val == null ? "Please select a priority" : null,
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5902),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _submitRequest,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Submit",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
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
}
