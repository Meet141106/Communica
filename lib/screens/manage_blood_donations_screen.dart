import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'connected_donors_screen.dart'; // Import the new screen

class ManageBloodDonationsScreen extends StatefulWidget {
  const ManageBloodDonationsScreen({super.key});

  @override
  ManageBloodDonationsScreenState createState() =>
      ManageBloodDonationsScreenState();
}

class ManageBloodDonationsScreenState
    extends State<ManageBloodDonationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allDonations = [];
  String _selectedBloodGroup = 'All';
  String _selectedState = 'All';
  bool _isLoading = true;

  // Predefined data
  final List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];
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

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final query = supabase.from('user_donateblood').select(
          'id, user_uid, ngo_id, donor_age, blood_group, donor_city, donor_mobile, remarks, created_at, status');

      if (_selectedBloodGroup != 'All') {
        query.eq('blood_group', _selectedBloodGroup);
      }

      final response = await query;
      final donationsWithDetails =
          await Future.wait(response.map((donation) async {
        final user = await supabase
            .from('user_signup')
            .select('full_name, city, state')
            .eq('id', donation['user_uid'])
            .single();
        return {
          ...donation,
          'full_name': user['full_name'],
          'user_city': user['city'],
          'user_state': user['state'],
        };
      }).toList());

      if (mounted) {
        setState(() {
          _allDonations = donationsWithDetails.where((d) {
            final bloodGroupMatch = _selectedBloodGroup == 'All' ||
                d['blood_group'] == _selectedBloodGroup;
            final stateMatch =
                _selectedState == 'All' || (d['user_state'] == _selectedState);
            return bloodGroupMatch && stateMatch;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
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
      print('Attempting to update status for ID: $donationId to $status');
      final response = await supabase
          .from('user_donateblood')
          .update({'status': status}).eq('id', donationId);
      print('Update response raw: $response');
      final count = response?.length ?? 0;
      print('Affected rows: $count');
      if (count > 0) {
        print('Update successful, refreshing data');
      } else {
        print('Update failed, no rows affected');
      }
      if (mounted) {
        _fetchDonations();
      }
    } catch (e) {
      print('Update error: $e');
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
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Blood Donations',
          style: GoogleFonts.poppins(
            color: Colors.green.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
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
                  'Manage Blood Donations',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ).animate().slideX(
                    duration: 500.ms, begin: -1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'Track and manage blood donations efficiently.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ).animate().fadeIn(duration: 700.ms),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedBloodGroup,
                        items: _bloodGroups.map((String group) {
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Text(group,
                                style: GoogleFonts.poppins(
                                    color: Colors.green.shade900)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBloodGroup = newValue!;
                            _fetchDonations();
                          });
                        },
                        dropdownColor: Colors.white,
                        style:
                            GoogleFonts.poppins(color: Colors.green.shade900),
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.green.shade900),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedState,
                        items: _states.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(state,
                                style: GoogleFonts.poppins(
                                    color: Colors.green.shade900)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedState = newValue!;
                            _fetchDonations();
                          });
                        },
                        dropdownColor: Colors.white,
                        style:
                            GoogleFonts.poppins(color: Colors.green.shade900),
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green))
                      : _allDonations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bloodtype,
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
                                    'Try adjusting filters or check back later.',
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
                                if (donation['status'] != 'Pending') {
                                  return const SizedBox.shrink();
                                }
                                final createdAtString =
                                    donation['created_at'] as String?;
                                final createdAt = createdAtString != null
                                    ? DateTime.parse(createdAtString)
                                    : DateTime.now();
                                return _buildDonationCard(donation, createdAt);
                              },
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _allDonations
                            .any((d) => d['status'] == 'Contacted')
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConnectedDonorsScreen(
                                  donations: _allDonations
                                      .where((d) => d['status'] == 'Contacted')
                                      .toList(),
                                  bloodGroups: _bloodGroups,
                                  states: _states,
                                  initialBloodGroup: _selectedBloodGroup,
                                  initialState: _selectedState,
                                  onUpdateStatus: _updateDonationStatus,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                      'Connected Donors',
                      style: GoogleFonts.poppins(color: Colors.white),
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

  Widget _buildDonationCard(Map<String, dynamic> donation, DateTime createdAt) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.bloodtype, color: Colors.green.shade900),
        ),
        title: Text(
          'Donor: ${donation['full_name'] ?? 'Unknown'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood Group: ${donation['blood_group']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('State: ${donation['user_state'] ?? 'N/A'}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text(
                'City: ${donation['user_city'] ?? donation['donor_city'] ?? 'N/A'}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Age: ${donation['donor_age']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Mobile: ${donation['donor_mobile']}',
                style: GoogleFonts.poppins(color: Colors.black87)),
            Text('Remarks: ${donation['remarks'] ?? 'None'}',
                style: GoogleFonts.poppins(color: Colors.grey)),
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
                  style: GoogleFonts.poppins(color: Colors.green.shade900)),
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
          // if (mounted) {
          //   launchUrl(Uri.parse('tel://${donation['donor_mobile']}'));
          // }
        },
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
