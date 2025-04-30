import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  EventCreationScreenState createState() => EventCreationScreenState();
}

class EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    controller.text = DateFormat('yyyy-MM-dd').format(picked!);
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final ngoId = prefs.getString('ngo_id');
      if (ngoId == null) {
        throw Exception('NGO ID not found. Please log in again.');
      }

      final ngoData = await _supabaseService.fetchNgoData(ngoId);
      if (ngoData == null) {
        throw Exception('NGO data not found.');
      }

      final ngoName = ngoData['ngo_name'];

      await Supabase.instance.client.from('events').insert({
        'event_name': _eventNameController.text.trim(),
        'date': _dateController.text,
        'time': _timeController.text,
        'location': _locationController.text.trim(),
        'deadline': _deadlineController.text,
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'ngo_id': ngoId,
        'ngo_name': ngoName,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _eventNameController.clear();
      _dateController.clear();
      _timeController.clear();
      _locationController.clear();
      _deadlineController.clear();
      _categoryController.clear();
      _descriptionController.clear();

      Navigator.pop(context); // Return to NGOHomeScreen
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Event",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField("Event Name", _eventNameController),
                _buildTextFieldWithIcon(
                  "Date",
                  _dateController,
                  Icons.calendar_today,
                  () => _selectDate(_dateController),
                ),
                _buildTextFieldWithIcon(
                  "Time",
                  _timeController,
                  Icons.access_time,
                  _selectTime,
                ),
                _buildTextFieldWithIcon(
                  "Location",
                  _locationController,
                  Icons.location_on,
                  null,
                ),
                _buildTextFieldWithIcon(
                  "Registration Deadline",
                  _deadlineController,
                  Icons.calendar_today,
                  () => _selectDate(_deadlineController),
                ),
                _buildTextFieldWithIcon(
                  "Category",
                  _categoryController,
                  Icons.label,
                  null,
                ),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) => value!.isEmpty ? "This field is required" : null,
      ),
    );
  }

  Widget _buildTextFieldWithIcon(String hint, TextEditingController controller,
      IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(icon, color: Colors.green),
            onPressed: onTap,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) => value!.isEmpty ? "This field is required" : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Description",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) => value!.isEmpty ? "This field is required" : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Submit",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _deadlineController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
