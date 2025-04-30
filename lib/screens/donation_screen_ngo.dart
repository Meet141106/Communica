import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'request_blood_screen.dart';
import 'manage_blood_donations_screen.dart';
import 'manage_things_donation_screen.dart';
import 'manage_money_donation_screen.dart';
import 'manage_blood_requests_screen.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  DonationScreenState createState() => DonationScreenState();
}

class DonationScreenState extends State<DonationScreen> {
  String? _ngoId;
  // _pendingCounts is not final because it is updated in _fetchPendingCounts
  final Map<String, int> _pendingCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchNGOIdAndCounts();
  }

  Future<void> _fetchNGOIdAndCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ngoId = prefs.getString("ngo_id");
      _ngoId ??= "Unknown NGO";
    });
    await _fetchPendingCounts();
  }

  Future<void> _fetchPendingCounts() async {
    if (_ngoId == null) return;

    final supabase = Supabase.instance.client;
    const options = [
      'Manage Blood Donations',
      'Manage Item Donations',
      'Manage Money Donations',
      'Manage Blood Requests'
    ];

    for (String label in options) {
      String table;
      if (label.contains('Blood Donations')) {
        table = 'user_donateblood';
      } else if (label.contains('Item Donations')) {
        table = 'user_donatethings';
      } else if (label.contains('Money Donations')) {
        table = 'user_donatemoney';
      } else {
        table = 'user_requestblood';
      }
      int count = await supabase
          .from(table)
          .select('id')
          .eq('ngo_id', _ngoId!)
          .eq('status', 'Pending')
          .count(CountOption.exact)
          .then((value) => value.count ?? 0);
      setState(() {
        _pendingCounts[label] = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, // 4% of screen width
              vertical: screenHeight * 0.02, // 2% of screen height
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom AppBar-like header
                Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.green.shade900),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "NGO Donations",
                          style: GoogleFonts.poppins(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.05, // Responsive font
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.1), // Balance the layout
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Manage Contributions",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.07, // Responsive font
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ).animate().slideX(
                      duration: 500.ms,
                      begin: -1,
                      end: 0,
                      curve: Curves.easeOut,
                    ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "Track and manage donations and blood requests for NGO.",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey.shade700,
                  ),
                ).animate().fadeIn(duration: 700.ms),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  height: screenHeight * 0.6, // Constrain GridView height
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 180).floor();
                      crossAxisCount = crossAxisCount < 2
                          ? 2
                          : crossAxisCount > 3
                              ? 3
                              : crossAxisCount;
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: screenWidth * 0.04,
                          mainAxisSpacing: screenHeight * 0.02,
                          childAspectRatio: 0.75, // Adjusted for better fit
                        ),
                        itemCount: donationOptions.length,
                        itemBuilder: (context, index) {
                          final option = donationOptions[index];
                          final pendingCount =
                              _pendingCounts[option['label']] ?? 0;
                          return DonationCard(
                            icon: option['icon'],
                            label: option['label'],
                            onTap: (ctx) => option['onTap'](ctx),
                            pendingCount: pendingCount,
                          ).animate().fadeIn(
                                duration: 500.ms,
                                delay: (100 * index).ms,
                              );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                RequestBloodButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestBloodScreen(),
                      ),
                    );
                  },
                ).animate().shake(duration: 600.ms, hz: 2, delay: 1000.ms),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DonationCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Function(BuildContext) onTap;
  final int pendingCount;

  const DonationCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.pendingCount = 0,
  });

  @override
  DonationCardState createState() => DonationCardState();
}

class DonationCardState extends State<DonationCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onTap(context);
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade200,
                      ),
                      child: Icon(
                        widget.icon,
                        size: screenWidth * 0.1,
                        color: Colors.green.shade900,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      onPressed: () => widget.onTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                      child: const Text("Manage"),
                    ),
                  ],
                ),
                if (widget.pendingCount > 0)
                  Positioned(
                    top: screenHeight * 0.01,
                    right: screenWidth * 0.02,
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${widget.pendingCount}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
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
}

class RequestBloodButton extends StatelessWidget {
  final VoidCallback onTap;

  const RequestBloodButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.05,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                "Raise Blood Request",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> donationOptions = [
  {
    'icon': Icons.bloodtype,
    'label': 'Manage Blood Donations',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ManageBloodDonationsScreen()),
        ),
  },
  {
    'icon': Icons.card_giftcard,
    'label': 'Manage Item Donations',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ManageThingsDonationScreen()),
        ),
  },
  {
    'icon': Icons.monetization_on,
    'label': 'Manage Money Donations',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ManageMoneyDonationScreen()),
        ),
  },
  {
    'icon': Icons.local_hospital,
    'label': 'Manage Blood Requests',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ManageBloodRequestsScreen()),
        ),
  },
];
