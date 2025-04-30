/*import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Your Account Type',
          style: TextStyle(color: Colors.green.shade900),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/splash_logo.png', height: 80),
            SizedBox(height: 20),
            SignupOption(
              title: 'Sign up as a User',
              subtitle: 'Join a Movement, Make an Impact',
              imagePath: 'assets/splash_logo.png',
              onPressed: () {},
            ),
            SizedBox(height: 20),
            Divider(color: Colors.green.shade900, thickness: 1),
            SizedBox(height: 20),
            SignupOption(
              title: 'Sign up as an NGO',
              subtitle: 'Empower Communities, Create Change',
              imagePath: 'assets/splash_logo.png',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class SignupOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onPressed;

  SignupOption(
      {required this.title,
      required this.subtitle,
      required this.imagePath,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Image.asset(imagePath, height: 50),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onPressed,
          child: Text('Sign Up →'),
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'user_signup_screen.dart'; // Import user signup screen
import 'ngo_signup_screen.dart'; // Assuming there's an NGO signup screen

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
          'Choose Your Account Type',
          style: TextStyle(color: Colors.green.shade900),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/splash_logo.png', height: 80),
            const SizedBox(height: 20),
            SignupOption(
              title: 'Sign up as a User',
              subtitle: 'Join a Movement, Make an Impact',
              imagePath: 'assets/splash_logo.png',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSignupScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.green.shade900, thickness: 1),
            const SizedBox(height: 20),
            SignupOption(
              title: 'Sign up as an NGO',
              subtitle: 'Empower Communities, Create Change',
              imagePath: 'assets/splash_logo.png',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NgoSignupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SignupOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onPressed;

  const SignupOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Image.asset(imagePath, height: 50),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade900,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sign Up →', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
