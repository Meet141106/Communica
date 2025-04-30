import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConnectedDonorsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> donations;
  final List<String> bloodGroups;
  final List<String> states;
  final String initialBloodGroup;
  final String initialState;
  final Future<void> Function(String, String) onUpdateStatus;

  const ConnectedDonorsScreen({
    super.key,
    required this.donations,
    required this.bloodGroups,
    required this.states,
    required this.initialBloodGroup,
    required this.initialState,
    required this.onUpdateStatus,
  });

  @override
  ConnectedDonorsScreenState createState() => ConnectedDonorsScreenState();
}

class ConnectedDonorsScreenState extends State<ConnectedDonorsScreen> {
  late List<Map<String, dynamic>> _filteredDonations;
  String _selectedBloodGroup = 'All';
  String _selectedState = 'All';

  @override
  void initState() {
    super.initState();
    _selectedBloodGroup = widget.initialBloodGroup;
    _selectedState = widget.initialState;
    _filteredDonations = widget.donations.where((d) {
      final bloodGroupMatch = _selectedBloodGroup == 'All' ||
          d['blood_group'] == _selectedBloodGroup;
      final stateMatch =
          _selectedState == 'All' || (d['user_state'] == _selectedState);
      return bloodGroupMatch && stateMatch;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      _filteredDonations = widget.donations.where((d) {
        final bloodGroupMatch = _selectedBloodGroup == 'All' ||
            d['blood_group'] == _selectedBloodGroup;
        final stateMatch =
            _selectedState == 'All' || (d['user_state'] == _selectedState);
        return bloodGroupMatch && stateMatch;
      }).toList();
    });
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
          'Connected Donors',
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
                  'Connected Donors',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ).animate().slideX(
                    duration: 500.ms, begin: -1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'View and manage connected blood donors.',
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
                        items: widget.bloodGroups.map((String group) {
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
                            _applyFilters();
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
                        items: widget.states.map((String state) {
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
                            _applyFilters();
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
                  child: _filteredDonations.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bloodtype,
                                  size: 100, color: Color(0xFF9E9E9E)),
                              SizedBox(height: 20),
                              Text(
                                'No Connected Donors Found',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Try adjusting filters or check back later.',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredDonations.length,
                          itemBuilder: (context, index) {
                            final donation = _filteredDonations[index];
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
          value: donation['status'] ?? 'Contacted',
          items: ['Contacted', 'Completed'].map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status,
                  style: GoogleFonts.poppins(color: Colors.green.shade900)),
            );
          }).toList(),
          onChanged: (String? newStatus) {
            if (newStatus != null && newStatus != donation['status']) {
              widget.onUpdateStatus(donation['id'], newStatus);
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
