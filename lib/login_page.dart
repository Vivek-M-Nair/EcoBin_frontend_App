import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';
import 'main.dart'; // Allows dynamic construction of EcoBinHomePage
import 'collection_worker.dart';

class EcoBinLoginPage extends StatefulWidget {
  /// Dynamic dashboard destination callbacks based on evaluated backend roles
  final Widget userDashboardScreen;
  final Widget workerDashboardScreen;

  const EcoBinLoginPage({
    super.key,
    required this.userDashboardScreen,
    required this.workerDashboardScreen,
  });

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

  // --- DEVELOPMENT SWITCHER ---
  // Flip this to false to send requests directly to your live Spring Boot backend!
  static const bool useMockBackend = false;

  // Core backend URL updated to target your 8081 runtime instance port
  final String _backendUrl = 'http://10.181.174.87:8081/api/login';

  @override
  void initState() {
    super.initState();
    _loadCachedUserId();
  }

  /// Fetches saved user profile configuration credentials from storage cache
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
    } catch (_) {}
  }

  /// Saves the active authenticated ID and profile payload metrics into local cache memory
  Future<void> _saveSessionToCache(
    String userId,
    Map<String, dynamic> serverData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_id', userId);
      await prefs.setString('auth_user_session', jsonEncode(serverData));
    } catch (_) {}
  }

  /// Submits credentials to your Spring Boot REST Endpoint or mocks the call
  void _executeLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String userId = _userIdController.text.trim();
    final String password = _passwordController.text;

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1200));
      final mockRolePage = userId.startsWith("CW-")
          ? "collection_worker_page"
          : "user_page";
      final mockPayload = {
        "status": "success",
        "page": mockRolePage,
        "userId": userId,
        "workerId": userId,
        if (mockRolePage == "collection_worker_page") ...{
          "collection_worker_name": "Dave R.",
          "scheduledZoneName": "Zone A",
          "numberOfHouses": 10,
          "wardNumber": 12,
          "villageName": "Subhash Nagar",
        }
      };

      await _saveSessionToCache(userId, mockPayload);
      _handleRoleRouting(mockRolePage, userId, mockPayload);
    } else {
      try {
        final response = await http
            .post(
              Uri.parse(_backendUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'userId': userId,
                'password': password,
                'passkey': '',
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final String targetPage = responseData['page'] ?? '';

          // Inject user/worker identification into payload
          responseData['userId'] = userId;
          responseData['workerId'] = userId;
          responseData['houseId'] = userId;

          await _saveSessionToCache(userId, responseData);

          // Passes the response data map down to route handling setup dynamically
          _handleRoleRouting(targetPage, userId, responseData);
        } else {
          _handleLoginError(
            "Verification Failed",
            "The system ID or security password was invalid. Please double check.",
          );
        }
      } catch (e) {
        _handleLoginError(
          "Connection Failure",
          "Unable to connect to EcoBin core services. Ensure your server is active on port 8081.",
        );
      }
    }
  }

  /// Dynamically determines layout redirection paths based on system authorization rules
  void _handleRoleRouting(
    String targetPage,
    String identityLabel,
    Map<String, dynamic> responseData,
  ) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Widget destinationWidget;
    String welcomeMessage = "Welcome back, $identityLabel!";

    if (targetPage == "user_page") {
      // Inject response map details directly into our main homepage state tree
      destinationWidget = EcoBinHomePage(loginData: responseData);
      final String parsedName = responseData['userName'] ?? identityLabel;
      welcomeMessage = "Welcome back, $parsedName! 🌿";
    } else if (targetPage == "collection_worker_page") {
      destinationWidget = CollectionWorkerPage(loginData: responseData);
      welcomeMessage = "Field deployment initialized for $identityLabel!";
    } else {
      _showErrorDialog(
        title: "Access Restricted",
        message:
            "Mobile device execution rules only permit logging in as a Resident or Collection Worker.",
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            destinationWidget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          welcomeMessage,
          style: const TextStyle(
            color: Color(0xFF020617),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleLoginError(String header, String info) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(title: header, message: info);
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomErrorDialog(title: title, message: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      border: Border.all(color: const Color(0xFF1E293B)),
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
                        const Text(
                          'USER ID / WORKER ID',
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
                              return 'System Identification ID is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. house-bf21a004 or CW-1024',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EcoBinRegisterPage(loginPageScreen: widget),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fixed: Moved outside of the state class scope to resolve compilation errors
class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const CustomErrorDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  }
}
