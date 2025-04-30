import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String? userId;
  List<Map<String, dynamic>> donations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_uid');

    if (userId == null) {
      final user = supabase.auth.currentUser;
      if (user != null && user.email != null) {
        final response = await supabase
            .from('user_signup')
            .select('id')
            .eq('email', user.email!)
            .maybeSingle();

        if (response != null && response['id'] != null) {
          userId = response['id'];
          await prefs.setString('user_uid', userId!);
        }
      }
    }

    if (userId != null) {
      await _fetchUserDonations(userId!);
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("User ID not found. Please login again.")),
        );
      }
    }
  }

  Future<void> _fetchUserDonations(String uid) async {
    try {
      final bloodDonations =
          await supabase.from('user_donateblood').select().eq('user_uid', uid);
      final thingsDonations =
          await supabase.from('user_donatethings').select().eq('user_id', uid);
      final moneyDonations =
          await supabase.from('user_donatemoney').select().eq('user_id', uid);

      debugPrint("Blood Donations: $bloodDonations");
      debugPrint("Things Donations: $thingsDonations");
      debugPrint("Money Donations: $moneyDonations");

      setState(() {
        donations = [
          ...bloodDonations.map((d) => {...d, 'type': 'Blood'}),
          ...thingsDonations.map((d) => {...d, 'type': 'Things'}),
          ...moneyDonations.map((d) => {...d, 'type': 'Money'}),
        ];

        donations.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));

        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching donations: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        title: const Text(
          "My Donations",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Donations:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!isLoading && donations.isEmpty)
              const Expanded(child: Center(child: Text("No donations found."))),
            if (!isLoading && donations.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    return _buildDonationCard(donations[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final createdAt =
        donation['created_at']?.toString().split('T').first ?? 'N/A';

    String imagePath = 'assets/donate_money.png';
    if (donation['type'] == 'Blood') {
      imagePath = 'assets/donate_blood.png';
    } else if (donation['type'] == 'Things') {
      imagePath = 'assets/donate_things.png';
    }

    return GestureDetector(
      onTap: () => _showDonationDetails(donation),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['type'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text("Date: $createdAt",
                    style: const TextStyle(color: Colors.black87)),
                if (donation['type'] == "Blood")
                  Text("Blood Group: ${donation['blood_group']}",
                      style: const TextStyle(color: Colors.grey)),
                if (donation['type'] == "Things") ...[
                  Text("Category: ${donation['category']}",
                      style: const TextStyle(color: Colors.grey)),
                  Text("Quantity: ${donation['quantity']}",
                      style: const TextStyle(color: Colors.grey)),
                ],
                if (donation['type'] == "Money")
                  Text("Amount: ₹${donation['donation_amount']}",
                      style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    final createdAt =
        donation['created_at']?.toString().split('T').first ?? 'N/A';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${donation['type']} Donation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (donation.containsKey('donor_name'))
              Text("Donor Name: ${donation['donor_name']}"),
            if (donation['type'] == "Blood")
              Text("Blood Group: ${donation['blood_group']}"),
            if (donation['type'] == "Things") ...[
              Text("Category: ${donation['category']}"),
              Text("Quantity: ${donation['quantity']}"),
              Text("Pickup: ${donation['pickup_address']}"),
            ],
            if (donation['type'] == "Money")
              Text("Amount: ₹${donation['donation_amount']}"),
            Text("Date: $createdAt"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
