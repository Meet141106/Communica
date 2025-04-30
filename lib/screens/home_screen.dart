import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'app_drawer.dart';
import 'donation_screen.dart';
import 'edit_profile_screen.dart';
import 'blood_request_notification_screen.dart';
import 'ngo_details_screen.dart';
import 'event_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ngos = [];
  List<Map<String, dynamic>> filteredNgos = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> latestBloodRequests = [];
  bool isLoadingRequest = true;
  late AnimationController _glowController;
  late PageController _pageController;
  Timer? _carouselTimer;
  String? selectedCity;
  final List<String> cities = const [
    "All Cities",
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Kolkata",
    "Chennai",
    "Hyderabad",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Surat"
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: HomeScreen initState called');
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pageController = PageController(initialPage: 0);
    fetchNgos();
    fetchLatestBloodRequests();
    _startCarouselTimer();
    try {
      debugPrint(
          'DEBUG: Setting up real-time subscription for user_requestblood');
      supabase.from('user_requestblood').stream(primaryKey: ['id']).listen(
          (List<Map<String, dynamic>> data) {
        debugPrint('DEBUG: Real-time data received: ${data.length} records');
        debugPrint('DEBUG: Real-time data content: $data');
        if (mounted && data.isNotEmpty) {
          try {
            setState(() {
              latestBloodRequests = data
                  .where((request) => request['request_time'] != null)
                  .toList()
                ..sort((a, b) => DateTime.parse(b['request_time'])
                    .compareTo(DateTime.parse(a['request_time'])));
              if (latestBloodRequests.length > 2) {
                latestBloodRequests = latestBloodRequests.sublist(0, 2);
              }
              debugPrint(
                  'DEBUG: Updated latestBloodRequests: ${latestBloodRequests.map((r) => r['patient_name'] ?? 'Unknown').toList()}');
            });
          } catch (e) {
            debugPrint('DEBUG: Error processing real-time data: $e');
          }
        } else {
          debugPrint('DEBUG: No real-time data or widget not mounted');
        }
      }, onError: (error) {
        debugPrint('DEBUG: Real-time subscription error: $error');
      });
    } catch (e) {
      debugPrint('DEBUG: Failed to set up real-time subscription: $e');
    }
    searchController.addListener(() {
      debugPrint('DEBUG: Search query changed: ${searchController.text}');
      filterNgos();
    });
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

  Future<void> fetchNgos() async {
    debugPrint('DEBUG: Fetching NGOs');
    try {
      final response = await supabase.from('ngos').select();
      debugPrint('DEBUG: NGOs fetched: ${response.length} records');
      debugPrint('DEBUG: NGOs data: $response');
      if (mounted) {
        setState(() {
          ngos = List<Map<String, dynamic>>.from(response);
          filteredNgos = List.from(ngos);
          debugPrint('DEBUG: NGOs updated in state: ${ngos.length}');
        });
      } else {
        debugPrint('DEBUG: Widget not mounted, skipping NGO state update');
      }
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Error fetching NGOs: $e');
      debugPrint('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching NGOs: $e")),
        );
      }
    }
  }

  Future<void> fetchLatestBloodRequests() async {
    debugPrint('DEBUG: Fetching latest blood requests');
    try {
      final response = await supabase
          .from('user_requestblood')
          .select('*')
          .order('request_time', ascending: false)
          .limit(2);
      debugPrint(
          'DEBUG: Blood requests response: ${response.length} record(s)');
      debugPrint('DEBUG: Blood requests data: $response');
      if (mounted) {
        setState(() {
          latestBloodRequests = List<Map<String, dynamic>>.from(response);
          isLoadingRequest = false;
          debugPrint(
              'DEBUG: Latest blood requests updated: ${latestBloodRequests.map((r) => r['patient_name'] ?? 'None').toList()}');
        });
      } else {
        debugPrint('DEBUG: Widget not mounted, skipping blood requests update');
      }
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Error fetching blood requests: $e');
      debugPrint('DEBUG: Stack trace: $stackTrace');
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

  void filterNgos() {
    String query = searchController.text.toLowerCase();
    debugPrint('DEBUG: Filtering NGOs with query: $query, city: $selectedCity');
    setState(() {
      filteredNgos = ngos.where((ngo) {
        final matchesName =
            ngo['ngo_name']?.toLowerCase().contains(query) ?? false;
        final matchesCity = selectedCity == null ||
            selectedCity == 'All Cities' ||
            ngo['city'] == selectedCity;
        return matchesName && matchesCity;
      }).toList();
      debugPrint('DEBUG: Filtered NGOs count: ${filteredNgos.length}');
    });
  }

  @override
  void dispose() {
    debugPrint('DEBUG: HomeScreen dispose called');
    searchController.dispose();
    _glowController.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: Building HomeScreen UI');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: Text(
          "COMMUNICA",
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        )
            .animate()
            .slideX(
              duration: 600.ms,
              begin: -1,
              end: 0,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 600.ms),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.green.shade900),
            onPressed: () {
              debugPrint('DEBUG: Menu button pressed');
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.brown.shade900),
            onPressed: () {
              debugPrint('DEBUG: Notification button pressed');
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const BloodRequestNotificationScreen()),
                );
                debugPrint(
                    'DEBUG: Navigation to BloodRequestNotificationScreen from notification icon');
              } catch (e) {
                debugPrint(
                    'DEBUG: Error navigating from notification icon: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Navigation error: $e")),
                );
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildBanner(),
              const SizedBox(height: 30),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(child: _buildNgoList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBanner() {
    debugPrint('DEBUG: Building banner widget');
    debugPrint(
        'DEBUG: Banner state - isLoadingRequest: $isLoadingRequest, latestBloodRequests: ${latestBloodRequests.length}');
    return GestureDetector(
      onTap: latestBloodRequests.isNotEmpty
          ? () {
              debugPrint('DEBUG: Banner tapped');
              debugPrint(
                  'DEBUG: latestBloodRequests details: ${latestBloodRequests.map((r) => 'patient=${r['patient_name'] ?? 'Unknown'}, blood_group=${r['blood_group'] ?? 'N/A'}').toList()}');
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const BloodRequestNotificationScreen()),
                );
                debugPrint(
                    'DEBUG: Navigation to BloodRequestNotificationScreen initiated from banner');
              } catch (e) {
                debugPrint('DEBUG: Error navigating from banner: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Navigation error: $e")),
                );
              }
            }
          : () {
              debugPrint(
                  'DEBUG: Banner tapped but no blood requests available, ignoring tap');
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
          boxShadow: const [
            BoxShadow(
              color: Colors.red,
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: isLoadingRequest
            ? Center(
                child: CircularProgressIndicator(color: Colors.red.shade700),
              )
            : latestBloodRequests.isEmpty
                ? Center(
                    child: Text(
                      "No urgent blood requests. Be a hero, donate blood!",
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
                          return Row(
                            children: [
                              Icon(
                                Icons.local_hospital,
                                color: Colors.red.shade900,
                                size: 30,
                              ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.brown.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        onPageChanged: (index) => debugPrint(
                            'DEBUG: Viewing request: ${latestBloodRequests[index]['patient_name']}'),
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
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 4,
                                offset: Offset(0, 2),
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

  Widget _buildSearchBar() {
    debugPrint('DEBUG: Building search bar widget');
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search NGOs...",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon:
                  Icon(Icons.search, color: Colors.green.shade900, size: 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCity,
              hint: Text(
                "Select City",
                style: TextStyle(color: Colors.grey.shade500),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.green.shade900),
              items: cities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                debugPrint('DEBUG: City filter changed to: $newValue');
                setState(() {
                  selectedCity = newValue;
                  filterNgos();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNgoList() {
    debugPrint('DEBUG: Building NGO list with ${filteredNgos.length} items');
    return ListView.builder(
      itemCount: filteredNgos.length,
      itemBuilder: (context, index) {
        final ngo = filteredNgos[index];
        debugPrint('DEBUG: Rendering NGO: ${ngo['ngo_name'] ?? 'Unknown'}');
        return GestureDetector(
          onTap: () {
            debugPrint('DEBUG: NGO tapped: ${ngo['ngo_name'] ?? 'Unknown'}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NgoDetailsScreen(ngo: ngo),
              ),
            );
          },
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    child: ngo['logo_url'] != null && ngo['logo_url'].isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              ngo['logo_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    'DEBUG: Failed to load NGO logo: $error');
                                return Icon(
                                  Icons.account_circle,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ngo['ngo_name'] ?? 'Unknown NGO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Cause: ${ngo['cause'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.brown.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Location: ${ngo['city'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.brown.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: (100 * index).ms),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    debugPrint('DEBUG: Building bottom navigation bar');
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green.shade900,
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: Colors.white,
      elevation: 8,
      currentIndex: 0,
      onTap: (index) {
        debugPrint('DEBUG: Bottom navigation item tapped: $index');
        try {
          if (index == 0) {
            debugPrint('DEBUG: Navigating to EventScreen');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BloodRequestNotificationScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DonationScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EditProfileScreen()),
            );
          }
          debugPrint(
              'DEBUG: Navigation initiated for bottom nav index: $index');
        } catch (e) {
          debugPrint('DEBUG: Error navigating from bottom nav: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Navigation error: $e")),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: "Events",
          tooltip: "View Events",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active),
          label: "Requests",
          tooltip: "Blood Requests",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: "Donate",
          tooltip: "Make a Donation",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: "Profile",
          tooltip: "Edit Profile",
        ),
      ],
    );
  }
}
