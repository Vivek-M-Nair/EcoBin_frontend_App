import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EcoBinRegisterPage extends StatefulWidget {
  /// The login page screen widget to return to upon successful registration or cancellation
  final Widget loginPageScreen;

  const EcoBinRegisterPage({super.key, required this.loginPageScreen});

  @override
  State<EcoBinRegisterPage> createState() => _EcoBinRegisterPageState();
}

class _EcoBinRegisterPageState extends State<EcoBinRegisterPage> {
  // --- DEVELOPMENT MOCK MODE FLAG ---
  // Set this to false to test live requests with your local Spring Boot server!
  final bool useMockBackend = false;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // --- Dynamic Form Input States ---
  String _selectedType = 'House'; // Can be [House, Shop, Apartment, Building]
  String _selectedDistrict = 'Kottayam';
  String _selectedRegionSystem = 'Village'; // Can be [Village, Municipality]

  // Phase 1 Controllers
  final TextEditingController _propertyNameController = TextEditingController();
  final TextEditingController _propertyOwnerController =
      TextEditingController();
  final TextEditingController _propertyNumberController =
      TextEditingController();
  final TextEditingController _subNumberController = TextEditingController();
  final TextEditingController _regionNameController = TextEditingController();
  final TextEditingController _wardNumberController = TextEditingController();

  // Phase 2 Controllers (Shown after property verification is successful)
  String _generatedBackendUserId =
      ''; // Holds the 'houseId' returned by backend
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isStepVerified = false;
  bool _isLoading = false;

  final List<String> _propertyTypes = [
    'House',
    'Shop',
    'Apartment',
    'Building',
  ];
  final List<String> _districts = [
    'Kottayam',
    'Ernakulam',
    'Thiruvananthapuram',
    'Alappuzha',
    'Kozhikode',
  ];

  /// Step 1 Handshake: Verifies property details with Spring Boot User Verification Endpoint
  Future<void> _verifyPropertyWithBackend() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1400));
      setState(() {
        _generatedBackendUserId = "house-${UUID_LIKE_MOCK()}";
        _isStepVerified = true;
        _isLoading = false;
      });
    }
    {
      try {
        // Updated URL path to match your Spring Boot Controller mapping
        final url = Uri.parse(
          'http://10.181.174.87:8081/api/register/user/verify',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'districtName': _selectedDistrict,
            'houseName': _propertyNameController.text.trim(),
            'ownerName': _propertyOwnerController.text.trim(),
            'houseNumber': _propertyNumberController.text.trim(),
            'subNo': _subNumberController.text.trim(),
            'localBodyName': _regionNameController.text.trim(),
            'wardNo': int.tryParse(_wardNumberController.text.trim()) ?? 0,
          }),
        );

        if (response.statusCode == 200) {
          final responseBody = response.body.trim();

          // Intercept custom string validation warnings from backend
          if (responseBody.contains("House not found")) {
            _showErrorAlert(
              "Property Not Found",
              "House not found. Please register your house with the Government!",
            );
          } else if (responseBody == "account already exist") {
            _showErrorAlert(
              "Account Exists",
              "An active account is already fully registered for this house profile.",
            );
          } else {
            // Success payload delivers a map containing {"houseId": "..."}
            final data = jsonDecode(responseBody);
            setState(() {
              _generatedBackendUserId = data['houseId'] ?? '';
              _isStepVerified = true;
            });
          }
        } else {
          _showErrorAlert(
            "Server Error",
            "Server responded with code: ${response.statusCode}. Please try again later.",
          );
        }
      } catch (e) {
        _showErrorAlert(
          "System Offline",
          "Failed to communicate with EcoBin database. Verify your Spring Boot server application is running.",
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Step 2 Handshake: Submits the final user credentials to complete registration
  Future<void> _submitFinalRegistration() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _executeRedirectToLogin();
    } else {
      try {
        // Updated URL path to match user completion endpoint
        // Under _submitFinalRegistration()
        final url = Uri.parse(
          'http://10.181.174.87:8081/api/register/user/complete',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'houseId': _generatedBackendUserId,
            'password': _passwordController.text,
            'phoneNumber': _phoneController.text.trim(),
            'emailId': _emailController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          _executeRedirectToLogin();
        } else if (response.statusCode == 404) {
          _showErrorAlert(
            "Session Expired",
            "The verified temporary House ID was not located on the server database. Please retry step 1.",
          );
        } else {
          _showErrorAlert(
            "Registration Failed",
            "Server rejected database registration. Code: ${response.statusCode}",
          );
        }
      } catch (_) {
        _showErrorAlert(
          "Connection Interrupted",
          "Server failed to respond during secure profile synchronization.",
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String UUID_LIKE_MOCK() {
    return (10000000 + (StackTrace.current.hashCode % 90000000))
        .toString()
        .substring(0, 8);
  }

  void _executeRedirectToLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✨ House Registration Complete! Routing to login screen...",
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => widget.loginPageScreen),
    );
  }

  void _showErrorAlert(String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
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
          desc,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _propertyOwnerController.dispose();
    _propertyNumberController.dispose();
    _subNumberController.dispose();
    _regionNameController.dispose();
    _wardNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => widget.loginPageScreen),
            );
          },
        ),
        title: const Text(
          'Registration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                if (!_isStepVerified) ...[
                  // ==================== STEP 1: RECORD VERIFICATION ====================
                  Form(
                    key: _step1FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownLabel("Select Type"),
                        _buildStyledDropdown(
                          value: _selectedType,
                          items: _propertyTypes,
                          onChanged: (val) => setState(() {
                            _selectedType = val!;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownLabel("Select District"),
                        _buildStyledDropdown(
                          value: _selectedDistrict,
                          items: _districts,
                          onChanged: (val) => setState(() {
                            _selectedDistrict = val!;
                          }),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            border: Border.all(color: const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("$_selectedType Name"),
                              _buildTextFormField(
                                _propertyNameController,
                                "e.g. Green Valley $_selectedType",
                                Icons.business_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("$_selectedType Owner Name"),
                              _buildTextFormField(
                                _propertyOwnerController,
                                "Owner's full legal name",
                                Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel("$_selectedType No."),
                                        _buildTextFormField(
                                          _propertyNumberController,
                                          "e.g. 45/B",
                                          Icons.pin_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          "Sub-Number (Optional)",
                                        ),
                                        _buildTextFormField(
                                          _subNumberController,
                                          "e.g. G-01",
                                          Icons.tag_rounded,
                                          isRequired: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("Choose Region System"),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSegmentButton("Village"),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSegmentButton("Municipality"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("$_selectedRegionSystem Name"),
                              _buildTextFormField(
                                _regionNameController,
                                "Enter localized regional title",
                                Icons.map_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("Ward No."),
                              _buildTextFormField(
                                _wardNumberController,
                                "e.g. 12",
                                Icons.door_sliding_outlined,
                                isNumeric: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _verifyPropertyWithBackend,
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF020617),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified_user_rounded,
                                    size: 16,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Verifying Records...'
                                  : 'Verify Property Records',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: const Color(0xFF020617),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ==================== STEP 2: ACCOUNT CREATION ====================
                  Form(
                    key: _step2FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Property match found! Create your secure access profile below.",
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            border: Border.all(color: const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Assigned House tracking ID"),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020617),
                                  border: Border.all(
                                    color: const Color(0xFF1E293B),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _generatedBackendUserId,
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("Phone Number"),
                              _buildTextFormField(
                                _phoneController,
                                "9876543210",
                                Icons.phone_android_rounded,
                                isNumeric: true,
                                customValidator: (val) {
                                  if (val == null || val.trim().isEmpty) return null;
                                  final phone = val.trim();
                                  final reg = RegExp(r'^\d{10}$');
                                  if (!reg.hasMatch(phone)) {
                                    return 'Phone number must be exactly 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("Email Address"),
                              _buildTextFormField(
                                _emailController,
                                "username@domain.com",
                                Icons.alternate_email_rounded,
                                customValidator: (val) {
                                  if (val == null || val.trim().isEmpty) return null;
                                  final email = val.trim();
                                  if (!email.contains('@') || !email.endsWith('.com')) {
                                    return 'Email must contain @ and end with .com';
                                  }
                                  final reg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!reg.hasMatch(email)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel("Secure Password"),
                              _buildTextFormField(
                                _passwordController,
                                "••••••••••••",
                                Icons.lock_outline_rounded,
                                obscure: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _submitFinalRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: const Color(0xFF020617),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF020617),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Complete Secure Registration',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 1,
      ),
    ),
  );

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildStyledDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0F172A),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String value) {
    final bool isSelected = _selectedRegionSystem == value;
    return OutlinedButton(
      onPressed: () => setState(() {
        _selectedRegionSystem = value;
      }),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFF020617),
        side: BorderSide(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isRequired = true,
    bool isNumeric = false,
    bool obscure = false,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Field required';
        }
        if (customValidator != null) {
          return customValidator(value);
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
        fillColor: const Color(0xFF020617),
        filled: true,
        prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
