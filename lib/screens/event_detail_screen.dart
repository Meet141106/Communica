import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? ngoDetails;
  List<Map<String, dynamic>> registeredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        "EventDetailScreen: Initializing for event: ${widget.eventData['event_name']}");
    fetchNgoDetails();
    fetchRegisteredUsers();
  }

  Future<void> fetchNgoDetails() async {
    final ngoId = widget.eventData['ngo_id'];
    if (ngoId == null) return;

    try {
      final response =
          await supabase.from('ngos').select().eq('id', ngoId).single();
      debugPrint("fetchNgoDetails: Fetched NGO details for ID: $ngoId");
      setState(() {
        ngoDetails = response;
      });
    } catch (e) {
      debugPrint("fetchNgoDetails: Error fetching NGO details: $e");
    }
  }

  Future<void> fetchRegisteredUsers() async {
    try {
      debugPrint(
          "fetchRegisteredUsers: Fetching registrations for event ID: ${widget.eventData['id']}");
      final registrations = await supabase
          .from('event_registrations')
          .select()
          .eq('event_id', widget.eventData['id']);

      List<Map<String, dynamic>> usersWithDetails = [];

      for (var registration in registrations) {
        final userId = registration['user_id'];
        if (userId != null) {
          final user = await supabase
              .from('user_signup')
              .select()
              .eq('id', userId)
              .maybeSingle();

          usersWithDetails.add({
            'registration': registration,
            'user_signup': user ?? {},
          });
        }
      }

      debugPrint(
          "fetchRegisteredUsers: Fetched ${usersWithDetails.length} users with details");
      setState(() {
        registeredUsers = usersWithDetails;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("fetchRegisteredUsers: Error fetching registered users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildInfoRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$label:",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'N/A',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event['event_name'] ?? 'Event Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        "Event Details",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  buildInfoRow("Date", event['date'], Icons.calendar_today),
                  buildInfoRow("Time", event['time'], Icons.access_time),
                  buildInfoRow("Location", event['location'], Icons.place),
                  buildInfoRow("Category", event['category'], Icons.category),
                  const SizedBox(height: 12),
                  const Text(
                    "Description:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        "Registered Users",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total: ${registeredUsers.length} users",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                ],
              ),
            ),
            if (ngoDetails != null)
              buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          "Organized by NGO",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    buildInfoRow("Name", ngoDetails!['ngo_name'], Icons.group),
                    const SizedBox(height: 12),
                    const Text(
                      "About NGO:",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ngoDetails!['description'] ?? 'No description available',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}