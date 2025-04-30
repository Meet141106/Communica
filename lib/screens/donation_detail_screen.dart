import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> donation;

  const DonationDetailScreen({Key? key, required this.donation})
      : super(key: key);

  @override
  DonationDetailScreenState createState() => DonationDetailScreenState();
}

class DonationDetailScreenState extends State<DonationDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? ngoDetails;
  List<Map<String, dynamic>> registeredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNgoDetails();
    _fetchRegisteredUsers();
  }

  Future<void> _fetchNgoDetails() async {
    try {
      final ngoId = widget.donation['ngo_id'];
      final response =
          await supabase.from('ngos').select().eq('id', ngoId).single();
      setState(() {
        ngoDetails = response;
      });
    } catch (error) {
      debugPrint("Error fetching NGO details: $error");
    }
  }

  Future<void> _fetchRegisteredUsers() async {
    final eventId = widget.donation['id'];
    try {
      final registrations = await supabase
          .from('event_registrations')
          .select('user_id')
          .eq('event_id', eventId);

      final userIds = registrations.map((e) => e['user_id']).toList();

      if (userIds.isNotEmpty) {
        final usersResponse =
            await supabase.from('users').select().contains('id', userIds);
        setState(() {
          registeredUsers = List<Map<String, dynamic>>.from(usersResponse);
        });
      }
    } catch (error) {
      debugPrint("Error fetching registered users: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Registered Users'];
    sheet.appendRow(['User ID', 'Name', 'Email']);

    for (var user in registeredUsers) {
      sheet.appendRow([
        user['id'] ?? '',
        user['name'] ?? '',
        user['email'] ?? '',
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/RegisteredUsers.xlsx');
    final bytes = excel.encode();

    if (bytes != null) {
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel file saved at ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDonationInfo(donation),
                  const SizedBox(height: 20),
                  _buildNgoInfo(),
                  const SizedBox(height: 20),
                  _buildEventRegistrationsInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildDonationInfo(Map<String, dynamic> donation) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Donation Type", donation['type']),
            _infoRow("Donor Name", donation['donor_name']),
            _infoRow("Date", donation['created_at'].split('T')[0]),
            if (donation['type'] == "Blood") ...[
              _infoRow("Blood Group", donation['blood_group']),
            ] else if (donation['type'] == "Things") ...[
              _infoRow("Category", donation['category']),
              _infoRow("Quantity", donation['quantity'].toString()),
            ] else if (donation['type'] == "Money") ...[
              _infoRow("Amount", "₹${donation['donation_amount']}"),
            ],
            const SizedBox(height: 10),
            Text(
              "Remarks: ${donation['remarks'] ?? 'No remarks'}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNgoInfo() {
    if (ngoDetails == null) {
      return const Center(child: Text("NGO details not found"));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NGO Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow("NGO Name", ngoDetails!['name']),
            _infoRow("Email", ngoDetails!['email']),
            _infoRow("Contact", ngoDetails!['contact']),
            _infoRow("Address", ngoDetails!['address']),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRegistrationsInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Registered Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Total Registered: ${registeredUsers.length}"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: registeredUsers.isNotEmpty ? _exportToExcel : null,
              icon: const Icon(Icons.download),
              label: const Text("Download Excel"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
