import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';

class PastEventsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> pastEvents;

  const PastEventsScreen({super.key, required this.pastEvents});

  @override
  PastEventsScreenState createState() => PastEventsScreenState();
}

class PastEventsScreenState extends State<PastEventsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, String> ngoLogos = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("PastEventsScreen: Initializing");
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fetchNgoLogos();
    });
  }

  Future<void> _fetchNgoLogos() async {
    debugPrint("fetchNgoLogos: Fetching NGO logos");
    try {
      final ngoIds = widget.pastEvents
          .map((event) => event['ngo_id']?.toString())
          .where((id) => id != null)
          .toSet()
          .toList();

      if (ngoIds.isEmpty) {
        debugPrint("fetchNgoLogos: No NGO IDs to fetch");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      debugPrint("fetchNgoLogos: Fetching logos for NGOs: $ngoIds");
      final response = await supabase
          .from('ngos')
          .select('id, logo_url')
          .inFilter('id', ngoIds);

      debugPrint("fetchNgoLogos: Fetched ${response.length} logos");
      Map<String, String> logos = {};
      for (var ngo in response) {
        logos[ngo['id'].toString()] = ngo['logo_url'] ?? '';
      }

      if (mounted) {
        setState(() {
          ngoLogos = logos;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("fetchNgoLogos: Error fetching logos: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading NGO logos: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: const Text(
          "Past Events",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : widget.pastEvents.isEmpty
                ? const Center(
                    child: Text(
                      "No past events available.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: widget.pastEvents.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            "Past Events: ${widget.pastEvents.length}",
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        );
                      } else {
                        final event = widget.pastEvents[index - 1];
                        return _buildEventCard(event, index - 1);
                      }
                    },
                  ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final ngoId = event['ngo_id']?.toString();
    final logoUrl = ngoLogos[ngoId];

    debugPrint("buildEventCard: Rendering event: ${event['event_name']}");

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                ? NetworkImage(logoUrl)
                : const AssetImage("assets/ngo_logo.png") as ImageProvider,
            backgroundColor: Colors.grey.shade200,
            onBackgroundImageError: (_, __) {
              debugPrint("buildEventCard: Error loading logo for NGO ID: $ngoId");
            },
            child: logoUrl == null || logoUrl.isEmpty
                ? const Icon(Icons.image, color: Colors.grey, size: 25)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['event_name'] ?? 'Unknown Event',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Location: ${event['location'] ?? 'Unknown'}",
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Date: ${event['date'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
