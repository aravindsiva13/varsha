// import 'package:flutter/material.dart';
// import 'package:req_man/screens/dashboard_screen.dart';

// class SignInScreen extends StatefulWidget {
//   const SignInScreen({super.key});

//   @override
//   State<SignInScreen> createState() => _SignInScreenState();
// }

// class _SignInScreenState extends State<SignInScreen> {
//   final _formSignInKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool rememberPassword = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: MediaQuery.of(context).size.height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF009688),
//               Color(0xFF0277BD),
//             ],
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(vertical: 40),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.cloud,
//                   size: 80,
//                   color: Colors.white,
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "Cloud Admin Tracker",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 FractionallySizedBox(
//                   widthFactor: 0.92,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20.0, vertical: 22.0),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(28.0),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.18),
//                           blurRadius: 18,
//                           offset: const Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: Form(
//                       key: _formSignInKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           const Text(
//                             "Login",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 30,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 20.0),
//                           MouseRegion(
//                             cursor: SystemMouseCursors.text,
//                             child: TextFormField(
//                               controller: _emailController,
//                               style: const TextStyle(color: Colors.white),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter Email';
//                                 }
//                                 final emailRegex =
//                                     RegExp(r'^[\w\.-]+@riota\.in$');
//                                 if (!emailRegex.hasMatch(value.trim())) {
//                                   return 'Email must be a valid @riota.in address';
//                                 }
//                                 return null;
//                               },
//                               decoration: InputDecoration(
//                                 prefixIcon: const Icon(Icons.email,
//                                     color: Colors.white70),
//                                 hintText: 'Enter Email',
//                                 hintStyle:
//                                     const TextStyle(color: Colors.white70),
//                                 filled: true,
//                                 fillColor: Colors.white.withOpacity(0.06),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 16.0, horizontal: 12.0),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 labelStyle:
//                                     const TextStyle(color: Colors.white70),
//                                 label: const Text('Email',
//                                     style: TextStyle(color: Colors.white70)),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16.0),
//                           MouseRegion(
//                             cursor: SystemMouseCursors.text,
//                             child: TextFormField(
//                               controller: _passwordController,
//                               obscureText: true,
//                               obscuringCharacter: '.',
//                               style: const TextStyle(color: Colors.white),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter Password';
//                                 }
//                                 final passwordRegex = RegExp(
//                                     r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{6,}$');
//                                 if (!passwordRegex.hasMatch(value)) {
//                                   return 'Password must be alphanumeric & contain a special character';
//                                 }
//                                 return null;
//                               },
//                               decoration: InputDecoration(
//                                 prefixIcon: const Icon(Icons.lock,
//                                     color: Colors.white70),
//                                 hintText: 'Enter Password',
//                                 hintStyle:
//                                     const TextStyle(color: Colors.white70),
//                                 filled: true,
//                                 fillColor: Colors.white.withOpacity(0.06),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 16.0, horizontal: 12.0),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 labelStyle:
//                                     const TextStyle(color: Colors.white70),
//                                 label: const Text('Password',
//                                     style: TextStyle(color: Colors.white70)),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 22.0),
//                           MouseRegion(
//                             cursor: SystemMouseCursors.click,
//                             child: SizedBox(
//                               width: double.infinity,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Color(0xFF00BFA5),
//                                       Color(0xFF0277BD)
//                                     ],
//                                     begin: Alignment.centerLeft,
//                                     end: Alignment.centerRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.transparent,
//                                     shadowColor: Colors.transparent,
//                                     elevation: 0,
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 14),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   onPressed: () {
//                                     if (_formSignInKey.currentState!
//                                             .validate() &&
//                                         rememberPassword) {
//                                       Navigator.pushReplacement(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               DashboardScreen(),
//                                         ),
//                                       );
//                                     } else if (!rememberPassword) {
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                               'Please agree to the processing of personal data'),
//                                         ),
//                                       );
//                                     }
//                                   },
//                                   child: const Text(
//                                     'Sign in',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 18.0),
//                           Divider(
//                             thickness: 0.7,
//                             color: Colors.white.withOpacity(0.18),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//2

import 'package:flutter/material.dart';
import 'package:login_signup/screens/dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool rememberPassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formSignInKey.currentState!.validate()) {
      return;
    }

    if (!rememberPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the processing of personal data'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to connect to server - $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF009688),
              Color(0xFF0277BD),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Cloud Admin Tracker",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                FractionallySizedBox(
                  widthFactor: 0.92,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 22.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formSignInKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          MouseRegion(
                            cursor: SystemMouseCursors.text,
                            child: TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Email';
                                }
                                final emailRegex =
                                    RegExp(r'^[\w\.-]+@riota\.in$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Email must be a valid @riota.in address';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email,
                                    color: Colors.white70),
                                hintText: 'Enter Email',
                                hintStyle:
                                    const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                label: const Text('Email',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          MouseRegion(
                            cursor: SystemMouseCursors.text,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              obscuringCharacter: '•',
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Password';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock,
                                    color: Colors.white70),
                                hintText: 'Enter Password',
                                hintStyle:
                                    const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                label: const Text('Password',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22.0),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00BFA5),
                                      Color(0xFF0277BD)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18.0),
                          Divider(
                            thickness: 0.7,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ],
                      ),
                    ),
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
