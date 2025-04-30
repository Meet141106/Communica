import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonateThingsScreen extends StatefulWidget {
  const DonateThingsScreen({super.key});

  @override
  _DonateThingsScreenState createState() => _DonateThingsScreenState();
}

class _DonateThingsScreenState extends State<DonateThingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _pickupAddressController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedCategory;
  String? ngoId;

  final List<String> categories = [
    "Leftover Food",
    "Clothes",
    "Toys for Children",
    "Food Grains",
    "Vegetables/Fruits",
    "Grocery Items",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadNgoId();
  }

  Future<void> _loadNgoId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ngoId = prefs.getString('ngo_id');
    });
  }

  Future<void> _submitDonation() async {
    if (_formKey.currentState!.validate()) {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not logged in."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await supabase.from('user_donatethings').insert({
          'user_id': userId,
          'ngo_id': ngoId,
          'donor_name': _nameController.text,
          'donor_mobile': _mobileController.text,
          'category': _selectedCategory,
          'remarks': _remarksController.text.isNotEmpty
              ? _remarksController.text
              : null,
          'pickup_address': _pickupAddressController.text,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Donation Request Submitted!"),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        _nameController.clear();
        _mobileController.clear();
        _remarksController.clear();
        _pickupAddressController.clear();
        _quantityController.clear();
        setState(() {
          _selectedCategory = null;
        });

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
    _nameController.dispose();
    _mobileController.dispose();
    _remarksController.dispose();
    _pickupAddressController.dispose();
    _quantityController.dispose();
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
          "Donate Things",
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
                Text(
                  "Donate Things",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "Please fill the form & submit to make the donation",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                buildTextField(
                  "Donor Full Name",
                  _nameController,
                  Icons.person,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter full name"
                      : null,
                ),
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
                buildDropdownField(),
                if (_selectedCategory == "Other")
                  buildTextField(
                    "Specify Other (Remarks)",
                    _remarksController,
                    Icons.edit,
                    validator: (value) => value == null || value.isEmpty
                        ? "Please specify details"
                        : null,
                  ),
                buildTextField(
                  "Pickup Address",
                  _pickupAddressController,
                  Icons.location_on,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter pickup address"
                      : null,
                ),
                buildTextField(
                  "Quantity",
                  _quantityController,
                  Icons.inventory,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter quantity";
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return "Enter a valid quantity";
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.03), // Responsive spacing
                Center(
                  child: ElevatedButton(
                    onPressed: _submitDonation,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
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
        value: _selectedCategory,
        items: categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) => value == null ? "Please select a category" : null,
        decoration: InputDecoration(
          labelText: "Donation Category",
          prefixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
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
