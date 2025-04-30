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
    _loadNgoId(); // Load NGO ID when screen initializes
  }

  Future<void> _loadNgoId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ngoId = prefs.getString('ngo_id'); // Fetch NGO ID from shared preferences
    });
  }

  Future<void> _submitDonation() async {
    if (_formKey.currentState!.validate()) {
      final supabase = Supabase.instance.client;

      try {
        await supabase.from('donate_things').insert({
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
          const SnackBar(content: Text("Donation Request Submitted!")),
        );

        // Clear form fields after submission
        _formKey.currentState!.reset();
        _nameController.clear();
        _mobileController.clear();
        _remarksController.clear();
        _pickupAddressController.clear();
        _quantityController.clear();
        setState(() {
          _selectedCategory = null;
        });

        // Navigate back to the previous screen
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
          "Donate Things",
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
                "Donate Things",
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
              buildDropdownField(),
              if (_selectedCategory == "Other")
                buildTextField(
                    "Specify Other (Remarks)", _remarksController, Icons.edit),
              buildTextField("Pickup Address", _pickupAddressController,
                  Icons.location_on),
              buildTextField("Quantity", _quantityController, Icons.inventory,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitDonation,
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
        ),
      ),
    );
  }
}
