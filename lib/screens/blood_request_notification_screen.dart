import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BloodRequestNotificationScreen extends StatefulWidget {
  const BloodRequestNotificationScreen({super.key});

  @override
  _BloodRequestNotificationScreenState createState() =>
      _BloodRequestNotificationScreenState();
}

class _BloodRequestNotificationScreenState
    extends State<BloodRequestNotificationScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showAllRequests = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: BloodRequestNotificationScreen initState called');
    _fetchBloodRequests();
  }

  Future<void> _fetchBloodRequests() async {
    print('DEBUG: Fetching blood requests, showAll: $_showAllRequests');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      var query = Supabase.instance.client.from('user_requestblood').select();

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (!_showAllRequests) {
        query = query.gte('request_time', sevenDaysAgo.toIso8601String());
      } else {
        query = query.lt('request_time', sevenDaysAgo.toIso8601String());
      }

      final response = await query.order('request_time', ascending: false);

      print('DEBUG: Blood requests fetched: ${response.length} records');
      print('DEBUG: Blood requests data: $response');

      if (mounted) {
        setState(() {
          _requests = response;
          _isLoading = false;
        });
      } else {
        print('DEBUG: Widget not mounted, skipping blood requests update');
      }
    } catch (e) {
      print('DEBUG: Error fetching blood requests: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleRequestView() {
    setState(() {
      _showAllRequests = !_showAllRequests;
      _requests = [];
    });
    print('DEBUG: Toggled to ${_showAllRequests ? "past" : "recent"} requests');
    _fetchBloodRequests();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building BloodRequestNotificationScreen UI');
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E5902)),
          onPressed: () {
            print('DEBUG: Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Blood Request Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5902),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E5902)))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      "Error: $_errorMessage",
                      style: const TextStyle(
                        color: Color(0xFF2E5902),
                        fontSize: 16,
                      ),
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_hospital,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _showAllRequests
                                  ? "No past blood requests found."
                                  : "No recent blood requests.",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF2E5902),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _toggleRequestView,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E5902),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                _showAllRequests
                                    ? "Show Recent Requests"
                                    : "Show Past Requests",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          print(
                              'DEBUG: Rendering blood request: ${request['patient_name'] ?? 'Unknown'}');
                          return _buildRequestCard(request, index);
                        },
                      ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final requestTime = DateTime.parse(request['request_time']);
    final formattedTime =
        DateFormat('dd MMM yyyy, hh:mm a').format(requestTime);
    final urgency = request['urgency'] ?? // Use stored urgency if available
        (_showAllRequests ||
                DateTime.now().difference(requestTime).inHours >= 24
            ? "Normal"
            : "Urgent"); // Fallback logic

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
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
                          request['patient_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E5902),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (urgency == "Urgent") ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Urgent",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    request['blood_group'] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.black54, size: 20),
                const SizedBox(width: 5),
                Text(
                  request['mobile_number'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.black54, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    request['address'] ?? 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.black54, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    request['remarks']?.isEmpty ?? true
                        ? 'No remarks'
                        : request['remarks'],
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.black54, size: 20),
                const SizedBox(width: 5),
                Text(
                  "Urgency: $urgency",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Requested on: $formattedTime",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (100 * index).ms);
  }
}