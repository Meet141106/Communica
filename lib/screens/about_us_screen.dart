import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  final TextEditingController feedbackController = TextEditingController();

  AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Us",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our Team",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 10),
            const TeamMember(
              imageUrl: "assets/deep.png",
              name: "Deep Chotaliya",
              qualification: "3rd year diploma in IT",
            ),
            const TeamMember(
              imageUrl: "assets/ajudia.png",
              name: "Meet Ajudia",
              qualification: "3rd year diploma in IT",
            ),
            const TeamMember(
              imageUrl: "assets/patel.png",
              name: "Meet Vasani",
              qualification: "3rd year diploma in IT",
            ),
            const SizedBox(height: 20),
            Text(
              "Our Mission",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Communica is a community-focused mobile app that connects users with verified NGOs to support social causes. It allows NGOs to create and manage events, while users can easily discover, participate, and contribute through donations or volunteering. A standout feature is the real-time blood donation module, linking donors with hospitals and NGOs based on location and availability. Designed for transparency and impact, it brings people and organizations together for real-time community change.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Feedback",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      hintText: "Your Valuable Feedback",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        String feedback = feedbackController.text;
                        if (feedback.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Feedback Submitted!"),
                            ),
                          );
                          feedbackController.clear();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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

// Reusable Team Member Widget
class TeamMember extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String qualification;

  const TeamMember({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.qualification,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage(imageUrl),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(qualification),
    );
  }
}
