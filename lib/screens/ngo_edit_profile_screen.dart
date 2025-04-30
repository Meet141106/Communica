import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class NGOEditProfileScreen extends StatefulWidget {
  const NGOEditProfileScreen({super.key});

  @override
  NGOEditProfileScreenState createState() => NGOEditProfileScreenState();
}

class NGOEditProfileScreenState extends State<NGOEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();

  File? _imageFile;
  String? _ngoId;
  String? _logoUrl;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchNGODetails();
  }

  // Fetch NGO Details
  Future<void> _fetchNGODetails() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _ngoId = prefs.getString('ngo_id');

    if (_ngoId == null) {
      _showSnackBar('No NGO ID found');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _supabaseService.fetchNgoData(_ngoId!);
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['ngo_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _contactController.text = data['phone_number'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _registrationController.text = data['registration_number'] ?? '';
          _logoUrl = data['logo_url'];
          _isLoading = false;
        });
      } else {
        throw Exception('No data returned for NGO');
      }
    } catch (e) {
      _showSnackBar('Error loading NGO data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  // Update Profile
  Future<void> _updateProfile() async {
    if (_ngoId == null || !_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    setState(() => _isUploading = true);

    String? uploadedImageUrl;
    if (_imageFile != null) {
      try {
        uploadedImageUrl = await _supabaseService.uploadLogo(_imageFile!.path);
      } catch (e) {
        _showSnackBar('Error uploading logo: $e');
        setState(() => _isUploading = false);
        return;
      }
    }

    final updateData = {
      'ngo_name': _nameController.text,
      'phone_number': _contactController.text,
      'website':
          _websiteController.text.isEmpty ? null : _websiteController.text,
      'description': _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      if (uploadedImageUrl != null) 'logo_url': uploadedImageUrl,
    };

    try {
      print('Updating NGO with ID: $_ngoId, data: $updateData');
      final success = await _supabaseService.updateNgoData(_ngoId!, updateData);
      if (success) {
        _showSnackBar('Profile updated successfully!', isSuccess: true);
        await _fetchNGODetails();
      } else {
        _showSnackBar('Failed to update profile');
      }
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Show SnackBar
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
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
        title: const Text(
          'Edit NGO Profile',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      Center(
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.green, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : _logoUrl != null && _logoUrl!.isNotEmpty
                                          ? NetworkImage(_logoUrl!)
                                          : const AssetImage(
                                                  'assets/default_profile.png')
                                              as ImageProvider,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                              if (_isUploading)
                                const CircularProgressIndicator(
                                    color: Colors.green),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Form Fields
                      _buildLabeledTextField(
                        'NGO Name',
                        _nameController,
                        validator: (value) =>
                            value!.isEmpty ? 'NGO Name is required' : null,
                      ),
                      _buildLabeledTextField(
                        'Contact Number',
                        _contactController,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty
                            ? 'Contact Number is required'
                            : null,
                      ),
                      _buildLabeledTextField(
                        'Website',
                        _websiteController,
                        isOptional: true,
                        keyboardType: TextInputType.url,
                      ),
                      _buildLabeledTextField(
                        'Description',
                        _descriptionController,
                        isOptional: true,
                        maxLines: 4,
                      ),
                      _buildLabeledTextField(
                        'Email',
                        _emailController,
                        enabled: false,
                      ),
                      _buildLabeledTextField(
                        'Registration Number',
                        _registrationController,
                        enabled: false,
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade900,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int maxLines = 1,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
            validator: validator ??
                (isOptional
                    ? null
                    : (value) => value!.isEmpty ? '$label is required' : null),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _registrationController.dispose();
    super.dispose();
  }
}
