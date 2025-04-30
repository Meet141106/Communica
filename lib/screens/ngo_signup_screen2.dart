import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'signin_screen.dart';
import 'supabase_service.dart';

class NgoSignupScreen2 extends StatefulWidget {
  final String ngoName, regNumber, email, phone, password, city, cause;

  const NgoSignupScreen2({
    super.key,
    required this.ngoName,
    required this.regNumber,
    required this.email,
    required this.phone,
    required this.password,
    required this.city,
    required this.cause,
  });

  @override
  State<NgoSignupScreen2> createState() => _NgoSignupScreen2State();
}

class _NgoSignupScreen2State extends State<NgoSignupScreen2> {
  final SupabaseService _supabaseService = SupabaseService();
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isLoading = false;

  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController contactPhoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
        final url = await _supabaseService.uploadLogo(pickedFile.path);
        if (url != null && mounted) {
          setState(() {
            _imageUrl = url;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading logo: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    // Validate required fields
    if (contactPersonController.text.isEmpty ||
        contactPhoneController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final ngoData = {
      'ngo_name': widget.ngoName,
      'registration_number': widget.regNumber,
      'email': widget.email,
      'phone_number': widget.phone,
      'password': widget.password,
      'city': widget.city,
      'cause': widget.cause,
      'contact_person': contactPersonController.text,
      'contact_phone': contactPhoneController.text,
      'website': websiteController.text.isEmpty ? null : websiteController.text,
      'logo_url': _imageUrl,
      'description': descriptionController.text,
    };

    try {
      final success = await _supabaseService.registerNgo(ngoData);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NGO Registered Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error registering NGO, please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Step 2 of 2',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your organization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildTextField('Primary Contact Person Name',
                controller: contactPersonController),
            _buildTextField('Primary Contact Person’s Phone Number',
                controller: contactPhoneController),
            _buildTextField('Website / Social Links',
                controller: websiteController),
            const SizedBox(height: 10),
            const Text('Upload Logo'),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Center(
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, height: 70)
                      : _imageUrl != null
                          ? Image.network(_imageUrl!, height: 70)
                          : const Text('Upload',
                              style: TextStyle(color: Colors.black54)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField('Short NGO Description',
                controller: descriptionController, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit & Continue',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText,
      {TextEditingController? controller, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green),
          ),
        ),
        validator: hintText.contains('Website')
            ? null
            : (value) {
                if (value == null || value.isEmpty) {
                  return '$hintText is required';
                }
                return null;
              },
      ),
    );
  }
}
