import 'package:flutter/material.dart';
import 'ngo_signup_screen2.dart';
import 'signin_screen.dart';

class NgoSignupScreen extends StatefulWidget {
  const NgoSignupScreen({super.key});

  @override
  _NgoSignupScreenState createState() => _NgoSignupScreenState();
}

class _NgoSignupScreenState extends State<NgoSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ngoNameController = TextEditingController();
  final TextEditingController regNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController causeController = TextEditingController();

  final List<String> cities = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Kolkata",
    "Chennai",
    "Hyderabad",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Surat"
  ];

  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "NGO Registration",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/splash_logo.png', height: 80),
              const SizedBox(height: 20),
              _buildTextField("NGO Name", controller: ngoNameController),
              _buildTextField("Registration Number",
                  controller: regNumberController),
              _buildTextField("Email",
                  controller: emailController, isEmail: true),
              _buildTextField("Phone Number",
                  controller: phoneController, isPhone: true),
              _buildTextField("Password",
                  controller: passwordController, obscureText: true),
              _buildTextField("Confirm Password",
                  controller: confirmPasswordController, obscureText: true),
              _buildCityDropdown(),
              _buildTextField("Cause / Category", controller: causeController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Passwords do not match"),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NgoSignupScreen2(
                          ngoName: ngoNameController.text,
                          regNumber: regNumberController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          password: passwordController.text,
                          city: selectedCity ?? "",
                          cause: causeController.text,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 80),
                ),
                child: const Text("Create Account",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SigninScreen())),
                child: Text("Already have an account? Sign In",
                    style: TextStyle(color: Colors.green.shade900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText,
      {TextEditingController? controller,
      bool obscureText = false,
      bool isEmail = false,
      bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone
                ? TextInputType.phone
                : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return "$hintText is required";
          if (isEmail &&
              !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z]+\.[a-zA-Z]+").hasMatch(value)) {
            return "Enter a valid email";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade900)),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade900)),
        ),
        hint: const Text("City / Location"),
        value: selectedCity,
        onChanged: (String? newValue) {
          setState(() {
            selectedCity = newValue;
          });
        },
        items: cities.map((city) {
          return DropdownMenuItem<String>(value: city, child: Text(city));
        }).toList(),
      ),
    );
  }
}
