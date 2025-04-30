import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads an NGO logo to Supabase storage and returns the public URL.
  Future<String?> uploadLogo(String filePath) async {
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      const bucket = 'logos'; // Matches your existing Supabase bucket

      print('Uploading logo: $fileName to bucket: $bucket');

      // Upload file to Supabase storage
      await _supabase.storage.from(bucket).upload(
            'ngo_logos/$fileName', // Store in ngo_logos/ folder for organization
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final String publicUrl =
          _supabase.storage.from(bucket).getPublicUrl('ngo_logos/$fileName');
      print('Logo URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      rethrow; // Allow caller to handle errors
    }
  }

  /// Registers an NGO in the 'ngos' table.
  Future<bool> registerNgo(Map<String, dynamic> ngoData) async {
    try {
      print('Registering NGO with data: $ngoData');
      final response = await _supabase.from('ngos').insert(ngoData).select();
      print('Insert response: $response');
      return response.isNotEmpty;
    } catch (e) {
      print('Error registering NGO: $e');
      rethrow;
    }
  }

  /// Fetches NGO data by ID.
  Future<Map<String, dynamic>?> fetchNgoData(String ngoId) async {
    try {
      final response =
          await _supabase.from('ngos').select().eq('id', ngoId).single();
      return response;
    } catch (e) {
      print('Error fetching NGO data: $e');
      rethrow;
    }
  }

  /// Updates NGO data by ID.
  Future<bool> updateNgoData(
      String ngoId, Map<String, dynamic> updateData) async {
    try {
      print('Updating NGO with ID: $ngoId, data: $updateData');
      final response = await _supabase
          .from('ngos')
          .update(updateData)
          .eq('id', ngoId)
          .select();
      print('Update response: $response');
      return response.isNotEmpty;
    } catch (e) {
      print('Error updating NGO: $e');
      rethrow;
    }
  }
}
