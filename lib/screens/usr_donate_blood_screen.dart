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

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedBloodGroup;
  String? _ngoId;
  String? _userId;

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
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _ngoId = prefs.getString('ngo_id');
    _userId = prefs.getString('user_uid');

    if (_userId == null) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final result = await supabase
            .from('user_signup')
            .select('id')
            .eq('email', user.email as Object)
            .maybeSingle();

        if (result != null && result['id'] != null) {
          _userId = result['id'];
          await prefs.setString('user_uid', _userId!);
        }
      }
    }

    setState(() {});
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in!")),
        );
        return;
      }

      try {
        await supabase.from('user_donateblood').insert({
          'user_uid': _userId,
          'ngo_id': _ngoId,
          'donor_mobile': _mobileController.text,
          'donor_age': int.parse(_ageController.text),
          'blood_group': _selectedBloodGroup,
          'donor_city': _cityController.text,
          'remarks': _remarksController.text,
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Blood donation submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _ageController.dispose();
    _remarksController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjusts for keyboard
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Donate Blood",
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05, // Responsive font size
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, // 5% of screen width
            vertical: screenHeight * 0.02, // 2% of screen height
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField(
                  "Donor Mobile No",
                  _mobileController,
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter mobile number";
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return "Enter a valid 10-digit mobile number";
                    }
                    return null;
                  },
                ),
                buildTextField(
                  "Age",
                  _ageController,
                  Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter age";
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 18 || age > 65) {
                      return "Age must be between 18 and 65";
                    }
                    return null;
                  },
                ),
                buildTextField(
                  "City",
                  _cityController,
                  Icons.location_city,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter city"
                      : null,
                ),
                buildTextField(
                  "Remarks (Optional)",
                  _remarksController,
                  Icons.edit,
                  isOptional: true,
                ),
                buildDropdownField(),
                SizedBox(height: screenHeight * 0.03), // Responsive spacing
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15, // Responsive padding
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04, // Responsive font
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: isOptional ? null : validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 10,
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedBloodGroup,
        items: bloodGroups.map((group) {
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 10,
          ),
        ),
      ),
    );
  }
}
