import 'dart:convert';
import 'package:http/http.dart' as http;

Future<bool> sendOTP(String email) async {
  final url =
      Uri.parse("https://rwxyzkbloszbqhrvhbyz.functions.supabase.co/send-otp");

  final response = await http.post(
    url,
    headers: {
      "Authorization": "Bearer YOUR_ANON_KEY",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "email": email,
      "otp": "123456" 
    }),
  );

  if (response.statusCode == 200) {
    print("✅ OTP sent successfully!");
    return true;
  } else {
    print("❌ Failed to send OTP: ${response.body}");
    return false;
  }
}
