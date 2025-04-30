import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyRegisteredEventsScreen extends StatefulWidget {
  const MyRegisteredEventsScreen({super.key});

  @override
  State<MyRegisteredEventsScreen> createState() =>
      _MyRegisteredEventsScreenState();
}

class _MyRegisteredEventsScreenState extends State<MyRegisteredEventsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _registeredEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredEvents();
  }

  Future<void> _fetchRegisteredEvents() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final response = await supabase.from('event_registrations').select('''
            id,
            created_at,
            events (
              event_name,
              date,
              time,
              category,
              location,
              ngo_id,
              ngos (
                ngo_name,
                city
              )
            )
          ''').eq('user_id', user.id).order('created_at', ascending: false);

      setState(() {
        _registeredEvents = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching registered events: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "My Registered Events",
          style: TextStyle(
            color: Color(0xFF2E7D32), // Dark green
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registeredEvents.isEmpty
              ? const Center(
                  child: Text(
                    "You haven't registered for any events yet.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _registeredEvents.length,
                  itemBuilder: (context, index) {
                    final reg = _registeredEvents[index];
                    final event = reg['events'];
                    final ngo = event?['ngos'];

                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF81C784), // Light green
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event?['event_name'] ?? "Event",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32), // Green title
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Date: ${event?['date']}",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Time: ${event?['time']}",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.category,
                                      size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Category: ${event?['category']}",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Location: ${event?['location']}",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Colors.grey),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 20, color: Colors.green),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Organized by: ${ngo?['ngo_name'] ?? 'NGO'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (ngo?['city'] != null)
                                Text(
                                  "City: ${ngo!['city']}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                "You registered on: ${DateFormat.yMMMMd().add_jm().format(DateTime.parse(reg['created_at']))}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
