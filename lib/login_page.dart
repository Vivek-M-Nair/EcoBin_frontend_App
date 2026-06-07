import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';

class EcoBinLoginPage extends StatefulWidget {
  /// The destination route to direct the user upon successful login validation
  final Widget dashboardScreen;

  const EcoBinLoginPage({super.key, required this.dashboardScreen});

  @override
  State<EcoBinLoginPage> createState() => _EcoBinLoginPageState();
}

class _EcoBinLoginPageState extends State<EcoBinLoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCachedUser = false;

  // =========================================================================
  // --- FRONTEND DEVELOPER DEV-SWITCHER ---
  // =========================================================================
  // Since you haven't built your Spring Boot backend yet, keep this set to 'true'.
  // It will bypass the server, simulate a network request delay, and let you
  // test your user-id caching and app flows instantly!
  //
  // Switch to 'false' later to test your real Spring Boot REST API calls.
  static const bool useMockBackend = true;

  // Note: '10.0.2.2' is the special IP redirect address that points directly to your computer's
  // 'localhost' from inside an Android emulator (like MuMu Player or Android Studio Emulator).
  final String _backendUrl = 'http://10.0.2.2:8080/api/auth/login';

  @override
  void initState() {
    super.initState();
    _loadCachedUserId();
  }

  /// Fetches saved user profile configuration credentials from persistent hardware storage cache
  Future<void> _loadCachedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedId = prefs.getString('cached_user_id');
      if (cachedId != null && cachedId.isNotEmpty) {
        setState(() {
          _userIdController.text = cachedId;
          _isCachedUser = true;
        });
      }
    } catch (_) {
      // Resilient local runtime variable fallback if plugins are unconfigured
    }
  }

  /// Saves the active authenticated ID securely in persistent cache memory
  Future<void> _saveUserIdToCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_id', userId);
    } catch (_) {
      // Fail-safe protection mapping
    }
  }

  /// Submits credentials to your Spring Boot REST Endpoint or mocks the call
  void _executeLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String userId = _userIdController.text.trim();
      final String password = _passwordController.text;

      if (useMockBackend) {
        // --- 🧪 DEV MOCK BACKEND MODE ---
        // Simulate a realistic database search handshake delay
        await Future.delayed(const Duration(milliseconds: 1200));
        await _saveUserIdToCache(userId);
        _navigateToDashboard(userId);
      } else {
        // --- 🔌 SPRING BOOT BACKEND REST CALL ---
        try {
          // Send verification request to Spring Boot Auth Controller
          final response = await http
              .post(
                Uri.parse(_backendUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonEncode({'userId': userId, 'password': password}),
              )
              .timeout(
                const Duration(seconds: 10),
              ); // Set a robust timeout threshold

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Success pathway: User verified in Spring Boot database
            await _saveUserIdToCache(userId);
            _navigateToDashboard(userId);
          } else {
            // Failure pathway: Credentials rejected by Spring Boot
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _showErrorDialog(
                title: "Verification Failed",
                message:
                    "The entered User ID or Password was incorrect. Please check your credentials or register a new profile.",
              );
            }
          }
        } catch (e) {
          // Exception pathway: Server unreachable or offline
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog(
              title: "Connection Timed Out",
              message:
                  "Unable to reach the backend services. Please ensure your Spring Boot application is running on port 8080, and the local endpoint path '/api/auth/login' exists.",
            );
          }
        }
      }
    }
  }

  /// Coordinates the transition directly to Dashboard Home Page
  void _navigateToDashboard(String userId) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.dashboardScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🌿 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  "Welcome back, $userId!",
                  style: const TextStyle(
                    color: Color(0xFF020617),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  /// Displays a clean modal window outlining the specific error state
  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A), // Slate 900
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handles guest routing and bypasses cache requirements
  void _executeGuestLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.dashboardScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Logged in as Guest Rider 👤",
          style: TextStyle(
            color: Color(0xFF020617),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Slate 950 App Base
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top App Branding
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF10B981),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    text: 'Eco',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Bin',
                        style: TextStyle(color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'A SMART WASTE MANAGEMENT SYSTEM',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Core Login Panel
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // Slate 900
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                      ), // Slate 800
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter credentials to synchronize your metrics.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // USER ID FIELD
                        const Text(
                          'USER ID',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _userIdController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'User ID is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. AM-8902',
                            hintStyle: const TextStyle(
                              color: Color(0xFF475569),
                            ),
                            fillColor: const Color(0xFF020617),
                            filled: true,
                            prefixIcon: const Icon(
                              Icons.account_circle_outlined,
                              color: Color(0xFF475569),
                              size: 20,
                            ),
                            suffixIcon: _isCachedUser
                                ? Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.2),
                                      ),
                                    ),
                                    child: const Text(
                                      'CACHED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF334155),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PASSWORD FIELD
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            hintStyle: const TextStyle(
                              color: Color(0xFF475569),
                            ),
                            fillColor: const Color(0xFF020617),
                            filled: true,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF475569),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF475569),
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF334155),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _executeLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: const Color(0xFF020617),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF020617),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Sign In Securely',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Smoothly transitions from the login screen over to your dynamic registration view
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EcoBinRegisterPage(
                              loginPageScreen:
                                  widget, // Passes the current login page instance as a fallback reference
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Register first',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFF1E293B))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 16),

                // Guest Login Alternative Option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _executeGuestLogin,
                    icon: const Icon(Icons.person_outline_rounded, size: 16),
                    label: const Text(
                      'Continue as Guest Rider',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE2E8F0),
                      side: const BorderSide(color: Color(0xFF1E293B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
