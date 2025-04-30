import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ContactedBloodRequestsScreen extends StatefulWidget {
  const ContactedBloodRequestsScreen({super.key});

  @override
  ContactedBloodRequestsScreenState createState() =>
      ContactedBloodRequestsScreenState();
}

class ContactedBloodRequestsScreenState
    extends State<ContactedBloodRequestsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allRequests = [];
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
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final query = supabase
          .from('user_requestblood')
          .select(
              'id, user_id, ngo_id, request_time, patient_name, mobile_number, remarks, address, blood_group, status')
          .eq('status', 'Contacted') // Show only Contacted
          .order('request_time', ascending: true); // Earliest first

      final response = await query;
      logger.i('Fetch response: $response');
      final requestsWithDetails =
          await Future.wait(response.map((request) async {
        final userId = request['user_id'] as String?;
        if (userId == null) {
          logger.w('User ID is null for request: $request');
          return {
            ...request,
            'user_full_name': request['patient_name'] ?? 'Unknown',
            'user_city': 'N/A',
            'user_state': 'N/A',
            'user_phone': request['mobile_number'] ?? 'N/A',
            'user_email': 'N/A',
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
          ...request,
          'user_full_name':
              user['full_name'] ?? request['patient_name'] ?? 'Unknown',
          'user_city': user['city'] ?? 'N/A',
          'user_state': user['state'] ?? 'N/A',
          'user_phone': user['phone'] ?? request['mobile_number'] ?? 'N/A',
          'user_email': user['email'] ?? 'N/A',
        };
      }).toList());

      if (mounted) {
        setState(() {
          _allRequests = requestsWithDetails.where((r) {
            final stateMatch =
                _selectedState == 'All' || (r['user_state'] == _selectedState);
            return stateMatch;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Fetch requests error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching requests: $e')),
        );
      }
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      logger.i('Attempting to update status for ID: $requestId to $status');

      // Validate requestId format (UUID)
      if (requestId.isEmpty ||
          !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(requestId)) {
        logger.e('Invalid request ID format: $requestId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid request ID format')),
          );
        }
        return;
      }

      // Check if the request exists
      final checkResponse = await supabase
          .from('user_requestblood')
          .select('id')
          .eq('id', requestId)
          .maybeSingle();

      if (checkResponse == null) {
        logger.w('No request found for ID: $requestId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request not found')),
          );
        }
        return;
      }

      // Execute the update query
      logger.i(
          'Executing query: UPDATE user_requestblood SET status = \'$status\' WHERE id = \'$requestId\'');
      final response = await supabase
          .from('user_requestblood')
          .update({'status': status})
          .eq('id', requestId)
          .select()
          .maybeSingle();

      logger.i('Update response: $response');

      if (response != null) {
        logger.i('Update successful for request ID: $requestId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status')),
          );
          await _fetchRequests(); // Refresh data
        }
      } else {
        logger.w('Update failed, no rows affected for ID: $requestId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Failed to update status: No matching request found')),
          );
        }
      }
    } catch (e) {
      logger.e('Update error for ID: $requestId: $e');
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
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E5902)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contacted Blood Requests',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2E5902),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacted Blood Requests',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E5902),
              ),
            ).animate().slideX(
                duration: 500.ms, begin: -1, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'Track blood requests that have been contacted.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700]!,
              ),
            ).animate().fadeIn(duration: 700.ms),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedState,
              items: _states.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state,
                      style:
                          GoogleFonts.poppins(color: const Color(0xFF2E5902))),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedState = newValue!;
                  _fetchRequests();
                });
              },
              dropdownColor: Colors.white,
              style: GoogleFonts.poppins(color: const Color(0xFF2E5902)),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E5902)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2E5902)))
                  : _allRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_hospital,
                                  size: 60, color: Colors.red),
                              const SizedBox(height: 10),
                              Text(
                                'No Contacted Blood Requests',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: const Color(0xFF2E5902),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Try adjusting the state filter or check data.',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allRequests.length,
                          itemBuilder: (context, index) {
                            final request = _allRequests[index];
                            final requestTimeString =
                                request['request_time'] as String?;
                            final requestTime = requestTimeString != null
                                ? DateTime.parse(requestTimeString)
                                : DateTime.now();
                            return _buildRequestCard(
                                request, requestTime, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
      Map<String, dynamic> request, DateTime requestTime, int index) {
    final formattedTime =
        DateFormat('dd MMM yyyy, hh:mm a').format(requestTime);
    final urgency = DateTime.now().difference(requestTime).inHours < 24
        ? 'Urgent'
        : 'Normal';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          request['user_full_name'] ??
                              request['patient_name'] ??
                              'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E5902),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (urgency == 'Urgent') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Urgent',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    request['blood_group'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['user_phone'] ?? request['mobile_number'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['address'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['remarks']?.isEmpty ?? true
                        ? 'No remarks'
                        : request['remarks'],
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_city,
                    color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'City: ${request['user_city']}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.map, color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'State: ${request['user_state']}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.black54, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Urgency: $urgency',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Requested: $formattedTime',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownButton<String>(
                  value: request['status'] ?? 'Contacted',
                  items: ['Pending', 'Contacted', 'Fulfilled']
                      .map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status,
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF2E5902), fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (String? newStatus) {
                    if (newStatus != null &&
                        newStatus != (request['status'] ?? 'Contacted')) {
                      _updateRequestStatus(request['id'], newStatus);
                    }
                  },
                  dropdownColor: Colors.white,
                  style: GoogleFonts.poppins(color: const Color(0xFF2E5902)),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (100 * index).ms);
  }
}
