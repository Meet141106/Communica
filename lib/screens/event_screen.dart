import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'event_detail_screen.dart';
import 'event_registration_screen.dart';
import 'my_registered_events_screen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  EventScreenState createState() => EventScreenState();
}

class EventScreenState extends State<EventScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _events = [];
  Map<String, String> _ngoLogos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("EventScreen: Initializing");
    _fetchData();
  }

  Future<void> _fetchData() async {
    debugPrint("EventScreen: Fetching events and NGO logos");
    setState(() => _isLoading = true);
    try {
      await Future.wait([_fetchEvents(), _fetchNgoLogos()]);
    } catch (error) {
      debugPrint("EventScreen: Error fetching data: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final response = await supabase
          .from('events')
          .select('*')
          .order('date', ascending: true);

      final now = DateTime.now();
      final upcomingEvents = response.where((event) {
        final eventDate = DateTime.tryParse(event['date'] ?? '');
        return eventDate != null && eventDate.isAfter(now);
      }).toList();

      debugPrint(
          "fetchEvents: Fetched ${upcomingEvents.length} upcoming events");
      setState(() {
        _events = List<Map<String, dynamic>>.from(upcomingEvents);
      });
    } catch (error) {
      debugPrint("fetchEvents: Error fetching events: $error");
      rethrow;
    }
  }

  Future<void> _fetchNgoLogos() async {
    try {
      final ngoResponse = await supabase.from('ngos').select('id, logo_url');
      setState(() {
        _ngoLogos = {
          for (var ngo in ngoResponse)
            ngo['id'].toString(): ngo['logo_url'] ?? ''
        };
        debugPrint("fetchNgoLogos: Loaded ${_ngoLogos.length} NGO logos");
      });
    } catch (error) {
      debugPrint("fetchNgoLogos: Error fetching NGO logos: $error");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("build: Rendering EventScreen");
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Events",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _fetchData,
            tooltip: "Refresh Events",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: Colors.green,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green))
                  : _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 150,
                                color: Colors.grey.shade400,
                                semanticLabel: "No upcoming events icon",
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No Upcoming Events",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                semanticsLabel: "No Upcoming Events",
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Check back later for new events!",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                semanticsLabel:
                                    "Check back later for new events!",
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ListView.builder(
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              return GestureDetector(
                                onTap: () {
                                  debugPrint(
                                      "Event Card: Navigating to EventDetailScreen for event: ${event['event_name']}");
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailScreen(
                                        eventData: event,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildEventCard(context, event),
                              );
                            },
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint(
                        "ElevatedButton: Navigating to MyRegisteredEventsScreen");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MyRegisteredEventsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    "View My Registered Events",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final ngoId = event['ngo_id']?.toString();
    final logoUrl = ngoId != null ? _ngoLogos[ngoId] : null;

    debugPrint(
        "buildEventCard: Rendering event: ${event['event_name']}, NGO ID: $ngoId");

    if (ngoId == null) {
      debugPrint(
          "buildEventCard: Warning: ngo_id is null for event: ${event['event_name']}");
    }

    final timeString = event['time'] ?? "00:00";
    final DateFormat timeFormat = DateFormat("hh:mm a");
    final DateFormat dateFormat = DateFormat("dd-MM-yyyy");

    final time = DateTime.tryParse('2021-01-01 $timeString');
    final formattedTime = time != null ? timeFormat.format(time) : timeString;

    final date = DateTime.tryParse(event['date'] ?? '');
    final formattedDate =
        date != null ? dateFormat.format(date) : event['date'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: "NGO Logo for ${event['event_name']}",
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                      ? NetworkImage(logoUrl)
                      : const AssetImage("assets/ngo_logo.png")
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event['event_name'] ?? "Event Name",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel: event['event_name'] ?? "Event Name",
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16, color: Colors.green.shade800),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.green.shade800),
              const SizedBox(width: 6),
              Text(
                formattedTime,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event['location'] ?? "Location",
                  style: const TextStyle(color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event['description'] ?? "No description available.",
            style: const TextStyle(color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint(
                    "ElevatedButton: Navigating to EventRegistrationScreen for event: ${event['event_name']}");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventRegistrationScreen(
                      event: event,
                      ngoLogos: _ngoLogos, // Pass the ngoLogos map
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
              icon: const Icon(Icons.event_available,
                  size: 18, color: Colors.white),
              label: const Text(
                "Register",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}