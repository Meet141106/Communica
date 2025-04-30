import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  _MyDonationsScreenState createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String? ngoId;
  List<Map<String, dynamic>> donations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNgoId();
  }

  Future<void> _loadNgoId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('ngo_id');

    if (mounted) {
      setState(() {
        ngoId = id;
      });
    }

    await _fetchDonations(id!);
  }

  Future<void> _fetchDonations(String ngoId) async {
    try {
      final bloodDonations =
          await supabase.from('blood_donations').select().eq('ngo_id', ngoId);
      final thingsDonations =
          await supabase.from('donate_things').select().eq('ngo_id', ngoId);
      final moneyDonations =
          await supabase.from('money_donations').select().eq('ngo_id', ngoId);

      debugPrint("Blood Donations: $bloodDonations");
      debugPrint("Things Donations: $thingsDonations");
      debugPrint("Money Donations: $moneyDonations");

      if (mounted) {
        setState(() {
          donations = [
            ...bloodDonations.map((donation) => {...donation, 'type': 'Blood'}),
            ...thingsDonations
                .map((donation) => {...donation, 'type': 'Things'}),
            ...moneyDonations.map((donation) => {...donation, 'type': 'Money'}),
          ];

          donations.sort((a, b) => DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));

          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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

  /// Helper function to get donation image based on type
  String _getDonationImage(String type) {
    switch (type) {
      case 'Blood':
        return 'assets/donate_money.png';
      case 'Things':
        return 'assets/donate_things.png';
      case 'Money':
        return 'assets/donate_money.png';
      default:
        return 'assets/donation_icon.png';
    }
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
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
              backgroundImage: AssetImage(_getDonationImage(donation['type'])),
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
                Text(
                  "Date: ${donation['created_at'].split('T')[0]}",
                  style: const TextStyle(color: Colors.black87),
                ),
                if (donation['type'] == "Blood") ...[
                  Text("Blood Group: ${donation['blood_group']}",
                      style: const TextStyle(color: Colors.grey)),
                ] else if (donation['type'] == "Things") ...[
                  Text("Category: ${donation['category']}",
                      style: const TextStyle(color: Colors.grey)),
                  Text("Quantity: ${donation['quantity']}",
                      style: const TextStyle(color: Colors.grey)),
                ] else if (donation['type'] == "Money") ...[
                  Text("Amount: ₹${donation['amount']}",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${donation['type']} Donation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Donor Name: ${donation['donor_name']}"),
            if (donation['type'] == "Blood") ...[
              Text("Blood Group: ${donation['blood_group']}"),
            ] else if (donation['type'] == "Things") ...[
              Text("Category: ${donation['category']}"),
              Text("Quantity: ${donation['quantity']}"),
            ] else if (donation['type'] == "Money") ...[
              Text("Amount: ₹${donation['amount']}"),
            ],
            Text("Date: ${donation['created_at'].split('T')[0]}"),
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
