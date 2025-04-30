import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ManageMoneyDonationScreen extends StatefulWidget {
  const ManageMoneyDonationScreen({super.key});

  @override
  ManageMoneyDonationScreenState createState() =>
      ManageMoneyDonationScreenState();
}

class ManageMoneyDonationScreenState extends State<ManageMoneyDonationScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allDonations = [];
  final List<String> _states = [
    'All',
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'West Bengal',
    'Tamil Nadu',
    'Telangana',
    'Gujarat'
  ];
  String _selectedState = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final query = supabase.from('user_donatemoney').select(
          'id, user_id, ngo_id, donation_amount, created_at, donor_name, donor_email, donor_mobile, remarks, status');

      final response = await query;
      logger.i('Fetch response: $response');
      final donationsWithDetails =
          await Future.wait(response.map((donation) async {
        final userId = donation['user_id'] as String?;
        if (userId == null) {
          logger.w('User ID is null for donation: $donation');
          return {
            ...donation,
            'user_full_name': donation['donor_name'] ?? 'Unknown',
            'user_city': 'N/A',
            'user_state': 'N/A',
            'user_phone': donation['donor_mobile'] ?? 'N/A',
            'user_email': donation['donor_email'] ?? 'N/A',
          };
        }
        final user = await supabase
            .from('user_signup')
            .select('full_name, city, state, phone, email')
            .eq('id', userId)
            .single()
            .catchError((e) {
          logger.e('User fetch error for user_id $userId: $e');
          return {
            'full_name': 'Unknown',
            'city': 'N/A',
            'state': 'N/A',
            'phone': 'N/A',
            'email': 'N/A'
          };
        });
        return {
          ...donation,
          'user_full_name':
              user['full_name'] ?? donation['donor_name'] ?? 'Unknown',
          'user_city': user['city'] ?? 'N/A',
          'user_state': user['state'] ?? 'N/A',
          'user_phone': user['phone'] ?? donation['donor_mobile'] ?? 'N/A',
          'user_email': user['email'] ?? donation['donor_email'] ?? 'N/A',
        };
      }).toList());

      if (mounted) {
        setState(() {
          _allDonations = donationsWithDetails.where((d) {
            final stateMatch =
                _selectedState == 'All' || (d['user_state'] == _selectedState);
            return stateMatch;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Fetch donations error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching donations: $e')),
        );
      }
    }
  }

  Future<void> _updateDonationStatus(String donationId, String status) async {
    try {
      logger.i('Attempting to update status for ID: $donationId to $status');

      // Validate donationId format (UUID)
      if (donationId.isEmpty ||
          !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(donationId)) {
        logger.e('Invalid donation ID format: $donationId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid donation ID format')),
          );
        }
        return;
      }

      // Check if the donation exists
      final checkResponse = await supabase
          .from('user_donatemoney')
          .select('id')
          .eq('id', donationId)
          .maybeSingle();

      if (checkResponse == null) {
        logger.w('No donation found for ID: $donationId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation not found')),
          );
        }
        return;
      }

      // Execute the update query
      logger.i(
          'Executing query: UPDATE user_donatemoney SET status = \'$status\' WHERE id = \'$donationId\'');
      final response = await supabase
          .from('user_donatemoney')
          .update({'status': status})
          .eq('id', donationId)
          .select()
          .maybeSingle();

      logger.i('Update response: $response');

      if (response != null) {
        logger.i('Update successful for donation ID: $donationId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status')),
          );
          await _fetchDonations(); // Refresh data
        }
      } else {
        logger.w('Update failed, no rows affected for ID: $donationId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to update status: No matching donation found')),
          );
        }
      }
    } catch (e) {
      logger.e('Update error for ID: $donationId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
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
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Money Donations',
          style: GoogleFonts.poppins(
            color: Colors.green[900]!,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Money Donations',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900]!,
                  ),
                ).animate().slideX(
                    duration: 500.ms, begin: -1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'Track and manage monetary contributions efficiently.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700]!,
                  ),
                ).animate().fadeIn(duration: 700.ms),
                const SizedBox(height: 24),
                DropdownButton<String>(
                  value: _selectedState,
                  items: _states.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state,
                          style:
                              GoogleFonts.poppins(color: Colors.green[900]!)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedState = newValue!;
                      _fetchDonations();
                    });
                  },
                  dropdownColor: Colors.white,
                  style: GoogleFonts.poppins(color: Colors.green[900]!),
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green))
                      : _allDonations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.monetization_on,
                                      size: 100, color: Color(0xFF9E9E9E)),
                                  SizedBox(height: 20),
                                  Text(
                                    'No Donations Found',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Try adjusting the state filter or check data.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _allDonations.length,
                              itemBuilder: (context, index) {
                                final donation = _allDonations[index];
                                final createdAtString =
                                    donation['created_at'] as String?;
                                final createdAt = createdAtString != null
                                    ? DateTime.parse(createdAtString)
                                    : DateTime.now();
                                return _buildDonationCard(donation, createdAt);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation, DateTime createdAt) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.monetization_on, color: Colors.green),
        ),
        title: Text(
          'Donor: ${donation['user_full_name'] ?? donation['donor_name'] ?? 'Unknown'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${donation['donation_amount']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Email: ${donation['user_email'] ?? donation['donor_email']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Phone: ${donation['user_phone'] ?? donation['donor_mobile']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Remarks: ${donation['remarks'] ?? 'None'}',
                style: GoogleFonts.poppins(color: Colors.grey)),
            Text('City: ${donation['user_city']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('State: ${donation['user_state']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Date: ${DateFormat('dd-MM-yyyy').format(createdAt)}',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
        trailing: DropdownButton<String>(
          value: donation['status'] ?? 'Pending',
          items: ['Pending', 'Contacted', 'Completed'].map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status,
                  style: GoogleFonts.poppins(color: Colors.green[900]!)),
            );
          }).toList(),
          onChanged: (String? newStatus) {
            if (newStatus != null &&
                newStatus != (donation['status'] ?? 'Pending')) {
              _updateDonationStatus(donation['id'], newStatus);
            }
          },
          dropdownColor: Colors.white,
        ),
        onTap: () {
          // Placeholder for contact functionality
        },
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
