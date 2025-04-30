import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'ngo_app_drawer.dart';
import 'event_creation_screen.dart';
import 'past_events_screen.dart';
import 'event_detail_screen.dart';
import 'blood_request_notification_screen.dart';

class NGOHomeScreen extends StatefulWidget {
  const NGOHomeScreen({super.key});

  @override
  NGOHomeScreenState createState() => NGOHomeScreenState();
}

class NGOHomeScreenState extends State<NGOHomeScreen>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> upcomingEvents = [];
  List<Map<String, dynamic>> pastEvents = [];
  List<Map<String, dynamic>> latestBloodRequests = [];
  Map<String, String> ngoLogos = {};
  int unreadNotificationCount = 0;
  bool isLoading = true;
  bool isLoadingRequest = true;
  late AnimationController _glowController;
  late PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    debugPrint("NGOHomeScreen: Initializing");
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pageController = PageController(initialPage: 0);
    _fetchData();
    _startCarouselTimer();
    try {
      supabase.from('user_requestblood').stream(primaryKey: ['id']).listen(
        (List<Map<String, dynamic>> data) {
          debugPrint("Real-time: Received ${data.length} blood requests");
          if (mounted) {
            setState(() {
              unreadNotificationCount = data.length;
              debugPrint(
                  "Real-time: Updated unread count to $unreadNotificationCount");
              latestBloodRequests = data
                  .where((request) => request['request_time'] != null)
                  .toList()
                ..sort((a, b) => DateTime.parse(b['request_time'])
                    .compareTo(DateTime.parse(a['request_time'])));
              if (latestBloodRequests.length > 2) {
                latestBloodRequests = latestBloodRequests.sublist(0, 2);
              }
              debugPrint(
                  "Real-time: Updated latestBloodRequests: ${latestBloodRequests.map((r) => r['patient_name'] ?? 'Unknown').toList()}");
            });
          }
        },
        onError: (error) {
          debugPrint("Real-time: Blood request stream error: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Real-time blood requests unavailable")),
            );
            _fetchLatestBloodRequests(); // Fallback to manual fetch
          }
        },
      );
    } catch (e) {
      debugPrint("Real-time: Failed to initialize stream: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to connect to real-time updates")),
        );
        _fetchLatestBloodRequests();
      }
    }
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && latestBloodRequests.isNotEmpty) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= latestBloodRequests.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    });
  }

  Future<void> _fetchData() async {
    debugPrint("NGOHomeScreen: Fetching data");
    setState(() {
      isLoading = true;
      isLoadingRequest = true;
    });
    try {
      await Future.wait([_fetchEvents(), _fetchLatestBloodRequests()]);
      debugPrint("NGOHomeScreen: Data fetch completed");
    } catch (e) {
      debugPrint("NGOHomeScreen: Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchEvents() async {
    debugPrint("fetchEvents: Fetching events and NGO logos");
    try {
      final eventResponse = await supabase.from('events').select();
      final ngoResponse = await supabase.from('ngos').select('id, logo_url');

      debugPrint(
          "fetchEvents: Fetched ${eventResponse.length} events and ${ngoResponse.length} NGOs");

      Map<String, String> logos = {};
      for (var ngo in ngoResponse) {
        logos[ngo['id'].toString()] = ngo['logo_url'] ?? '';
      }

      DateTime now = DateTime.now();
      List<Map<String, dynamic>> fetchedUpcoming = [];
      List<Map<String, dynamic>> fetchedPast = [];

      for (var event in eventResponse) {
        DateTime eventDate = DateTime.tryParse(event['date'] ?? '') ?? now;
        if (eventDate.isAfter(now)) {
          fetchedUpcoming.add(event);
        } else {
          fetchedPast.add(event);
        }
      }

      fetchedUpcoming.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
      fetchedPast.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      debugPrint(
          "fetchEvents: Upcoming: ${fetchedUpcoming.length}, Past: ${fetchedPast.length}");

      if (mounted) {
        setState(() {
          upcomingEvents = fetchedUpcoming;
          pastEvents = fetchedPast;
          ngoLogos = logos;
        });
      }
    } catch (e) {
      debugPrint("fetchEvents: Error fetching events: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading events: $e")),
        );
      }
    }
  }

  Future<void> _fetchLatestBloodRequests() async {
    debugPrint("fetchLatestBloodRequests: Fetching latest blood requests");
    try {
      final response = await supabase
          .from('user_requestblood')
          .select('*')
          .order('request_time', ascending: false)
          .limit(2);
      debugPrint(
          "fetchLatestBloodRequests: Fetched ${response.length} blood requests");
      if (mounted) {
        setState(() {
          latestBloodRequests = List<Map<String, dynamic>>.from(response);
          isLoadingRequest = false;
          debugPrint(
              "fetchLatestBloodRequests: Updated latestBloodRequests: ${latestBloodRequests.map((r) => r['patient_name'] ?? 'Unknown').toList()}");
        });
      }
    } catch (e) {
      debugPrint("fetchLatestBloodRequests: Error fetching blood requests: $e");
      if (mounted) {
        setState(() {
          isLoadingRequest = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching blood requests: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint("NGOHomeScreen: Disposing");
    _glowController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    supabase.removeAllChannels();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    debugPrint("build: Rendering NGOHomeScreen");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, color: Colors.brown.shade900),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              debugPrint("IconButton: Notification icon pressed");
              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const BloodRequestNotificationScreen(),
                  ),
                );
                debugPrint(
                    "Navigation: Returned from BloodRequestNotificationScreen");
                await _fetchLatestBloodRequests();
              } catch (e) {
                debugPrint(
                    "IconButton: Error navigating to BloodRequestNotificationScreen: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Navigation error: $e")),
                  );
                }
              }
            },
          ),
        ],
      ),
      drawer: const NGOAppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              SizedBox(height: screenHeight * 0.03),
              Text(
                "Existing Events: ${upcomingEvents.length}",
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "Upcoming event details:",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              isLoading
                  ? SizedBox(
                      height: screenHeight * 0.4,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      ),
                    )
                  : SizedBox(
                      height: screenHeight * 0.4,
                      child: upcomingEvents.isEmpty
                          ? const Center(
                              child: Text("No upcoming events available."))
                          : ListView.builder(
                              itemCount: upcomingEvents.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(upcomingEvents[index]);
                              },
                            ),
                    ),
              SizedBox(height: screenHeight * 0.03),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    debugPrint("TextButton: Navigating to PastEventsScreen");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PastEventsScreen(pastEvents: pastEvents),
                      ),
                    ).then((_) {
                      debugPrint(
                          "Navigation: Returned from PastEventsScreen, refreshing events");
                      _fetchEvents();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    backgroundColor: Colors.green.shade50,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  child: Text(
                    "View Past Events",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Add Event",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    debugPrint(
                        "ElevatedButton: Navigating to EventCreationScreen");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EventCreationScreen()),
                    ).then((_) {
                      debugPrint(
                          "Navigation: Returned from EventCreationScreen, refreshing events");
                      _fetchEvents();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    debugPrint("buildBanner: Building banner widget");
    debugPrint(
        "buildBanner: isLoadingRequest: $isLoadingRequest, latestBloodRequests: ${latestBloodRequests.length}");
    return GestureDetector(
      onTap: latestBloodRequests.isNotEmpty
          ? () {
              debugPrint("buildBanner: Banner tapped");
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const BloodRequestNotificationScreen()),
                );
                debugPrint(
                    "buildBanner: Navigated to BloodRequestNotificationScreen");
              } catch (e) {
                debugPrint("buildBanner: Error navigating: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Navigation error: $e")),
                  );
                }
              }
            }
          : () {
              debugPrint(
                  "buildBanner: Banner tapped but no blood requests, ignoring tap");
            },
      child: AnimatedContainer(
        duration: const Duration(seconds: 2),
        height: 105,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade200, Colors.red.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.red
                  .withOpacity((_glowController.value).clamp(0.0, 1.0) * 0.5),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoadingRequest
            ? Center(
                child: CircularProgressIndicator(color: Colors.red.shade700))
            : latestBloodRequests.isEmpty
                ? Center(
                    child: Text(
                      "No urgent blood requests. Encourage donations!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.brown.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        itemCount: latestBloodRequests.length,
                        controller: _pageController,
                        itemBuilder: (context, index) {
                          final request = latestBloodRequests[index];
                          debugPrint(
                              "buildBanner: Rendering request: ${request['patient_name'] ?? 'Unknown'}");
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.local_hospital,
                                    color: Colors.red.shade900, size: 30),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade900,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    request['blood_group'] ?? 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${request['patient_name'] ?? 'Unknown'} needs blood urgently!",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown.shade900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Requested: ${DateTime.tryParse(request['request_time'] ?? '') != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(request['request_time'])) : 'N/A'}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.brown.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onPageChanged: (index) => debugPrint(
                            "buildBanner: Viewing request: ${latestBloodRequests[index]['patient_name'] ?? 'Unknown'}"),
                      ).animate().fade(duration: 500.ms),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            "View More",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 1000.ms)
                            .then()
                            .shake(duration: 600.ms, hz: 2),
                      ),
                    ],
                  ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
          duration: 800.ms,
          curve: Curves.easeInOut,
          begin: const Offset(1, 1.05),
          end: const Offset(1.02, 1.02),
        );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final ngoId = event['ngo_id'].toString();
    final logoUrl = ngoLogos[ngoId];

    debugPrint("buildEventCard: Rendering event: ${event['event_name']}");

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
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
                debugPrint(
                    "buildEventCard: Error loading logo for NGO ID: $ngoId");
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
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    debugPrint(
        "showEventDetails: Navigating to EventDetailScreen for event: ${event['event_name']}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventData: event),
      ),
    );
  }
}