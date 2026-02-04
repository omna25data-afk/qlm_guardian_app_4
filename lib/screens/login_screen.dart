import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/providers/auth_provider.dart';
import 'package:guardian_app/features/auth/data/models/user_model.dart';
import 'package:guardian_app/screens/home_screen.dart';
import 'package:guardian_app/screens/debug_screen.dart';
import 'package:guardian_app/features/admin/presentation/screens/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse(ApiConstants.login);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'login_identifier': _identifierController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
             // is_guardian check logic removed

             // The HomeScreen will adapt based on the role in the future.
             
             const storage = FlutterSecureStorage();
             final token = data['token'] ?? data['access_token'];
             await storage.write(key: 'auth_token', value: token);
             await storage.write(key: 'user_data', value: jsonEncode(data));

             // Create User object
             final user = User.fromJson(data);
             
             // Update AuthProvider with user data
             if (mounted) {
               Provider.of<AuthProvider>(context, listen: false).setUser(user);
             }

             if (!mounted) return;

             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('تم تسجيل الدخول بنجاح!', style: GoogleFonts.tajawal()), backgroundColor: Colors.green),
             );

             // Check Role for Redirection
             // Check Role for Redirection
             if (user.roles.any((role) => [
               'super_admin', 
               'director', 
               'guardian_manager', 
               'documentation_head',
               'assistant_director'
             ].contains(role))) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
                );
             } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
             }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'فشل تسجيل الدخول';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'خطأ في الاتصال بالخادم (${response.statusCode})';
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/ministry_logo.jpg', height: 120),
                const SizedBox(height: 16),
                Text(
                  'وزارة العدل وحقوق الإنسان',
                  style: GoogleFonts.tajawal(textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
                ),
                Text(
                  'محكمة السياني الإبتدائية',
                  style: GoogleFonts.tajawal(textStyle: textTheme.bodyLarge?.copyWith(color: const Color(0xFF555555))),
                ),
                const SizedBox(height: 32),
                Text(
                  'نظام إدارة قلم التوثيق',
                  style: GoogleFonts.tajawal(textStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF006400))),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '(قلم التوثيق والأمناء الشرعيين)',
                   style: GoogleFonts.tajawal(textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF555555))),
                   textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.tajawal(color: Colors.red, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress, // Generic keyboard
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(),
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال أو البريد الإلكتروني',
                    labelStyle: GoogleFonts.tajawal(),
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال بيانات الدخول';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: GoogleFonts.tajawal(),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006400),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                // Debug Button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DebugScreen()),
                    );
                  },
                  icon: const Icon(Icons.bug_report, color: Colors.grey),
                  label: const Text("فحص الاتصال (Debug)", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
