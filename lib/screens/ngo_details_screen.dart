import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class NgoDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ngo;

  const NgoDetailsScreen({super.key, required this.ngo});

  Future<void> _launchUrl(BuildContext context, String url) async {
    debugPrint('DEBUG: Attempting to launch URL: $url');
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('DEBUG: Successfully launched $url');
    } else {
      debugPrint('DEBUG: Could not launch $url');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open $url")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: Text(
          ngo['ngo_name'] ?? 'NGO Details',
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 20 : 22,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () {
            debugPrint('DEBUG: Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dynamic Logo
              CircleAvatar(
                radius: isSmallScreen ? 60 : 80,
                backgroundColor: Colors.grey.shade200,
                child: ngo['logo_url'] != null && ngo['logo_url'].isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          ngo['logo_url'],
                          width: isSmallScreen ? 120 : 160,
                          height: isSmallScreen ? 120 : 160,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('DEBUG: Failed to load logo: $error');
                            return Icon(
                              Icons.account_circle,
                              size: isSmallScreen ? 120 : 160,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.account_circle,
                        size: isSmallScreen ? 120 : 160,
                        color: Colors.grey.shade400,
                      ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                ngo['ngo_name'] ?? 'Unknown NGO',
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ).animate().slideY(
                    duration: 600.ms,
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 8),
              Text(
                ngo['cause'] ?? 'N/A',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.brown.shade700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionCard(
                context,
                title: "About",
                children: [
                  _buildDetailRow(
                    icon: Icons.description,
                    label: "Description",
                    value: ngo['description'] ?? 'N/A',
                    isSmallScreen: isSmallScreen,
                  ),
                ],
                index: 0,
                isSmallScreen: isSmallScreen,
              ),

              // Contact Section
              _buildSectionCard(
                context,
                title: "Contact Information",
                children: [
                  _buildContactRow(
                    context,
                    icon: Icons.person,
                    label: "Contact Person",
                    value: ngo['contact_person'] ?? 'N/A',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildContactRow(
                    context,
                    icon: Icons.phone,
                    label: "Phone",
                    value: ngo['contact_phone'] ?? 'N/A',
                    onTap: ngo['contact_phone'] != null
                        ? () =>
                            _launchUrl(context, 'tel:${ngo['contact_phone']}')
                        : null,
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildContactRow(
                    context,
                    icon: Icons.email,
                    label: "Email",
                    value: ngo['email'] ?? 'N/A',
                    onTap: ngo['email'] != null
                        ? () => _launchUrl(context, 'mailto:${ngo['email']}')
                        : null,
                    isSmallScreen: isSmallScreen,
                  ),
                  if (ngo['website'] != null && ngo['website'].isNotEmpty)
                    _buildContactRow(
                      context,
                      icon: Icons.language,
                      label: "Website",
                      value: ngo['website'],
                      onTap: () => _launchUrl(context, ngo['website']),
                      isSmallScreen: isSmallScreen,
                    ),
                ],
                index: 1,
                isSmallScreen: isSmallScreen,
              ),

              // Details Section
              _buildSectionCard(
                context,
                title: "Details",
                children: [
                  _buildDetailRow(
                    icon: Icons.location_city,
                    label: "City",
                    value: ngo['city'] ?? 'N/A',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildDetailRow(
                    icon: Icons.verified,
                    label: "Registration Number",
                    value: ngo['registration_number'] ?? 'N/A',
                    isSmallScreen: isSmallScreen,
                  ),
                ],
                index: 2,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required int index,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 500.ms,
          delay: (100 * (index + 1)).ms,
        )
        .slideY(
          duration: 600.ms,
          begin: 0.2,
          end: 0,
          curve: Curves.easeOut,
        );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.brown.shade700,
            size: isSmallScreen ? 20 : 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.brown.shade700,
              size: isSmallScreen ? 20 : 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: onTap != null
                          ? Colors.blue.shade700
                          : Colors.brown.shade700,
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
