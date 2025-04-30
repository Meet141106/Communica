/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'ngo_signup_screen.dart';
import 'forget_password1.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _isNgoLoading = false;

  /// *Handles User Login*
  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        _clearFields(); // Clear input fields
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showErrorSnackbar("Invalid email or password. Try again.");
      }
    } on AuthException catch (e) {
      _showErrorSnackbar(e.message);
    } catch (e) {
      _showErrorSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// *Handles NGO Login*
  /// *Handles NGO Login*
  Future<void> _signInAsNgo() async {
    setState(() => _isNgoLoading = true);

    try {
      String inputEmail = _emailController.text.trim();
      debugPrint("Checking for NGO with email: $inputEmail");

      // Fetch NGO data
      final List<dynamic> result = await supabase
          .from('ngos')
          .select('id, email, password')
          .eq('email', inputEmail); // Change ilike to eq for an exact match

      debugPrint("Fetched Data: $result");

      if (result.isNotEmpty) {
        final ngoData = result.first;
        debugPrint("NGO Found: ${ngoData['email']}");

        if (ngoData['password'] == _passwordController.text.trim()) {
          debugPrint("Login successful!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showErrorSnackbar("Incorrect password. Try again.");
        }
      } else {
        _showErrorSnackbar("NGO not found. Please check your email.");
      }
    } catch (e) {
      _showErrorSnackbar("An error occurred while logging in.");
      debugPrint("NGO Login Error: $e");
    } finally {
      setState(() => _isNgoLoading = false);
    }
  }

  /// *Clears Input Fields After Login*
  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
  }

  /// *Displays SnackBar for Errors*
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/splash_logo.png',
                height: 100,
              ),
              const SizedBox(height: 30),
              _buildTextField(_emailController, _emailFocus, 'Email',
                  TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, _passwordFocus, 'Password',
                  TextInputType.text,
                  isPassword: true),
              const SizedBox(height: 10),
              _buildLinksRow(),
              const SizedBox(height: 20),
              _buildButton('SIGN IN', _signIn, _isLoading),
              const SizedBox(height: 15),
              const Text(
                'OR',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 15),
              _buildButton('Login as NGO', _signInAsNgo, _isNgoLoading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// *Reusable Text Field Widget*
  Widget _buildTextField(TextEditingController controller, FocusNode focusNode,
      String hint, TextInputType type,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: type,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// *Forgot Password & Signup Links*
  Widget _buildLinksRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ForgetPassword1Screen()),
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.green.shade900),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          ),
          child: Text(
            'New User?',
            style: TextStyle(color: Colors.green.shade900),
          ),
        ),
      ],
    );
  }

  /// *Reusable Button Widget*
  Widget _buildButton(String text, VoidCallback onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'ngo_home_screen.dart'; // ✅ Import NGO Home Screen
import 'package:shared_preferences/shared_preferences.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _isNgoLoading = false;

  /// *Handles User Login*
  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        _clearFields(); // Clear input fields
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showErrorSnackbar("Invalid email or password. Try again.");
      }
    } on AuthException catch (e) {
      _showErrorSnackbar(e.message);
    } catch (e) {
      _showErrorSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// *Handles NGO Login*

  Future<void> _signInAsNgo() async {
    setState(() => _isNgoLoading = true);

    try {
      String inputEmail = _emailController.text.trim();

      final List<dynamic> result = await supabase
          .from('ngos')
          .select('id, email, password')
          .eq('email', inputEmail);

      if (result.isNotEmpty) {
        final ngoData = result.first;

        if (ngoData['password'] == _passwordController.text.trim()) {
          String ngoId = ngoData['id']; // Store the ID

          // Save ID in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('ngo_id', ngoId);

          // Redirect to NGO Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NGOHomeScreen()),
          );
        } else {
          _showErrorSnackbar("Incorrect password. Try again.");
        }
      } else {
        _showErrorSnackbar("NGO not found. Please check your email.");
      }
    } catch (e) {
      _showErrorSnackbar("An error occurred while logging in.");
    } finally {
      setState(() => _isNgoLoading = false);
    }
  }

  /// *Clears Input Fields After Login*
  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
  }

  /// *Displays SnackBar for Errors*
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/splash_logo.png',
                height: 100,
              ),
              const SizedBox(height: 30),
              _buildTextField(_emailController, _emailFocus, 'Email',
                  TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, _passwordFocus, 'Password',
                  TextInputType.text,
                  isPassword: true),
              const SizedBox(height: 10),
              _buildLinksRow(),
              const SizedBox(height: 20),
              _buildButton('SIGN IN', _signIn, _isLoading),
              const SizedBox(height: 15),
              const Text(
                'OR',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 15),
              _buildButton('Login as NGO', _signInAsNgo, _isNgoLoading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// *Reusable Text Field Widget*
  Widget _buildTextField(TextEditingController controller, FocusNode focusNode,
      String hint, TextInputType type,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: type,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// *Forgot Password & Signup Links*
  Widget _buildLinksRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          ),
          child: Text(
            'New User?',
            style: TextStyle(color: Colors.green.shade900),
          ),
        ),
      ],
    );
  }

  /// *Reusable Button Widget*
  Widget _buildButton(String text, VoidCallback onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
    );
  }
}