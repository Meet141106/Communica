import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'usr_donate_blood_screen.dart';
import 'usr_donate_money_screen.dart';
import 'usr_donate_things_screen.dart';
import 'usr_request_blood.dart';
import 'Mydonation_screen_usr.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

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
          "Donations",
          style: GoogleFonts.poppins(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _DonationScreenBody(),
    );
  }
}

class _DonationScreenBody extends StatefulWidget {
  @override
  _DonationScreenBodyState createState() => _DonationScreenBodyState();
}

class _DonationScreenBodyState extends State<_DonationScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F5DC), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Make a Difference Today",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ).animate().slideX(
                  duration: 500.ms,
                  begin: -1,
                  end: 0,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 8),
            const Text(
              "Choose how you want to contribute to our community.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ).animate().fadeIn(duration: 700.ms),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: donationOptions.length,
                itemBuilder: (context, index) {
                  final option = donationOptions[index];
                  return DonationCard(
                    imagePath: option['imagePath'],
                    label: option['label'],
                    onTap: () => option['onTap'](context),
                  ).animate().fadeIn(
                        duration: 500.ms,
                        delay: (100 * index).ms,
                      );
                },
              ),
            ),
            const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}

class DonationCard extends StatefulWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const DonationCard({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  DonationCardState createState() => DonationCardState();
}

class DonationCardState extends State<DonationCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedScale(
        scale: _isTapped ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade200, Colors.green.shade100],
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.imagePath,
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.volunteer_activism,
                        size: 80,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade900,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Go",
                    style: TextStyle(fontSize: 14),
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade500],
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Text(
                "Request Blood Urgently",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
    'imagePath': 'assets/my_donations.png',
    'label': 'My Donations',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyDonationsScreen()),
        ),
  },
  {
    'imagePath': 'assets/donate_blood.png',
    'label': 'Register as Donor',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonateBloodScreen()),
        ),
  },
  {
    'imagePath': 'assets/donate_things.png',
    'label': 'Donate Things',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonateThingsScreen()),
        ),
  },
  {
    'imagePath': 'assets/donate_money.png',
    'label': 'Donate Money',
    'onTap': (BuildContext context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonateMoneyScreen()),
        ),
  },
];
