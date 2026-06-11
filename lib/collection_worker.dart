import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'main.dart';
import 'payment_page.dart';

// --- DEVELOPMENT ISOLATED RUNTIME BADGE ---
void main() => runApp(const TestWorkerApp());

class TestWorkerApp extends StatelessWidget {
  const TestWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CollectionWorkerPage(),
    );
  }
}

class CollectionWorkerPage extends StatefulWidget {
  final Map<String, dynamic> loginData;
  const CollectionWorkerPage({super.key, this.loginData = const {}});

  @override
  State<CollectionWorkerPage> createState() => _CollectionWorkerPageState();
}

class _CollectionWorkerPageState extends State<CollectionWorkerPage> {
  // --- PRODUCTION DEVELOPMENT MODE ROUTER SWITCH ---
  final bool useMockBackend = false;

  // Tracked Operations Datastructure Manifest Model Variables
  String _assignedWardName = "Pending assignment";
  int _assignedTotalHouseCount = 0;
  String _selectedPaymentVectorOption = "Pay as cash in office counter";
  bool _showCollectionUpdate = false;
  int _workerRating = 0;
  bool _isLoading = true;
  String _workerId = "";
  String _workerName = "Dave R.";
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _selectedZoneHouses = [];

  String _scheduledZoneName = "";
  int _numberOfHouses = 0;
  int _wardNumber = 0;
  String _villageName = "";
  String _nextAssignedDate = "No upcoming date";

  // Mock Notifications loaded dynamically
  final List<String> _notifications = [
    "🚨 ALERT: Route deviation detected near Ward 14.",
    "🌿 INFO: Garbage truck scheduled for maintenance tomorrow morning.",
    "⚠️ WARNING: High wind warnings are currently active for the sector.",
  ];

  // Active Manifest Collection Lists Model Mapping
  final List<Map<String, dynamic>> _houseManifestList = [
    {
      "houseNo": "14/A",
      "owner": "Vivek M Nair",
      "paymentStatus": "Paid",
      "feeAmount": 0,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/B",
      "owner": "Jacob Thomas",
      "paymentStatus": "Pending",
      "feeAmount": 240,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/C",
      "owner": "Jils Tom",
      "paymentStatus": "Paid",
      "feeAmount": 0,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/D",
      "owner": "Dr. Varun Nair",
      "paymentStatus": "Pending",
      "feeAmount": 240,
      "collectStatus": "Pending",
    },
  ];

  final TextEditingController _collectedCountController = TextEditingController(
    text: "46",
  );
  final TextEditingController _cashReceivedController = TextEditingController(
    text: "480",
  );
  final TextEditingController _pendingCountController = TextEditingController(
    text: "2",
  );
  final TextEditingController _pendingReasonController = TextEditingController(
    text: "Gate locked, dog inside properties",
  );
  final TextEditingController _expenseAmountController = TextEditingController();
  final TextEditingController _incidentReportController = TextEditingController();
  final TextEditingController _leaveDateController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  String _expenseMockImageBase64 = "";
  String _complaintMockImageBase64 = "";

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, Function(String) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final File file = File(image.path);
        final int sizeInBytes = await file.length();
        if (sizeInBytes > 2 * 1024 * 1024) {
          _showSnackBar("⚠️ Image size exceeds the 2MB limit.");
          return;
        }
        final bytes = await file.readAsBytes();
        String base64String = base64Encode(bytes);
        String formattedBase64 = "data:image/jpeg;base64,$base64String";
        onPicked(formattedBase64);
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e");
    }
  }

  void _showImageSourceDialog(Function(String) onPicked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
              title: const Text("Gallery", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, onPicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
              title: const Text("Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, onPicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _parseInjectedLoginData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getProfile();
    if (_workerId.isNotEmpty) {
      await getAssignments(_workerId);
      await _fetchAssignedAreaDetails();
      await _fetchScheduleQuietly();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchScheduleQuietly() async {
    if (useMockBackend) {
      setState(() {
        _nextAssignedDate = "2026-06-10";
        if (_assignedWardName == "Pending assignment") {
          _assignedWardName = "Zone: Zone A";
        }
      });
      return;
    }
    if (_workerId.isEmpty) return;
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/schedule/$_workerId');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> dates = data['assignedDates'] ?? [];
          setState(() {
            if (dates.isNotEmpty) {
              _nextAssignedDate = dates[0].toString();
            } else {
              _nextAssignedDate = "No upcoming date";
            }
            if (data['assignedZoneId'] != null) {
              _scheduledZoneName = data['assignedZoneId'].toString();
              _assignedWardName = "Zone: ${data['assignedZoneId']}";
            }
          });
        }
      }
    } catch (_) {}
  }

  void _parseInjectedLoginData() {
    if (widget.loginData.isNotEmpty) {
      setState(() {
        _workerId = widget.loginData['workerId'] ?? widget.loginData['userId'] ?? "";
        _workerName = widget.loginData['collection_worker_name'] ?? widget.loginData['workerName'] ?? widget.loginData['userName'] ?? "Dave R.";
        _scheduledZoneName = widget.loginData['scheduledZoneName'] ?? "";
        _numberOfHouses = widget.loginData['numberOfHouses'] ?? 0;
        _wardNumber = widget.loginData['wardNumber'] ?? 0;
        _villageName = widget.loginData['villageName'] ?? "";
      });
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return "Pending";
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> getProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionStr = prefs.getString('auth_user_session');
      String? token;
      if (sessionStr != null) {
        final session = jsonDecode(sessionStr);
        token = session['token'] ?? session['jwt'] ?? session['accessToken'];
        setState(() {
          _workerId = session['workerId'] ?? session['userId'] ?? _workerId;
          _workerName = session['collection_worker_name'] ?? session['workerName'] ?? session['userName'] ?? _workerName;
          _scheduledZoneName = session['scheduledZoneName'] ?? _scheduledZoneName;
          _numberOfHouses = session['numberOfHouses'] ?? _numberOfHouses;
          _wardNumber = session['wardNumber'] ?? _wardNumber;
          _villageName = session['villageName'] ?? _villageName;
        });
      }
      token ??= widget.loginData['token'] ?? widget.loginData['jwt'] ?? widget.loginData['accessToken'];

      if (_workerId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://10.181.174.87:8081/api/worker/profile/$_workerId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _workerName = data['name'] ?? data['collection_worker_name'] ?? _workerName;
            _workerId = data['workerId'] ?? data['userId'] ?? data['id'] ?? _workerId;
            _scheduledZoneName = data['scheduledZoneName'] ?? _scheduledZoneName;
            _numberOfHouses = data['numberOfHouses'] ?? _numberOfHouses;
            _wardNumber = data['wardNumber'] ?? _wardNumber;
            _villageName = data['villageName'] ?? _villageName;
          });
        }
      } else {
        debugPrint("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getAssignments(String workerId) async {
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/$workerId/assignments');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        setState(() {
          if (data is List) {
            _assignments = List<Map<String, dynamic>>.from(data.map((x) => Map<String, dynamic>.from(x)));
          } else {
            _assignments = [];
          }
        });
      } else {
        debugPrint("Failed to fetch assignments: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching assignments: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getHouses(String zoneId) async {
    final url = Uri.parse('http://10.181.174.87:8081/api/zone/$zoneId/houses');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        final houses = List<Map<String, dynamic>>.from(data.map((x) => Map<String, dynamic>.from(x)));
        setState(() {
          _selectedZoneHouses = houses;
        });
        return houses;
      }
    }
    throw Exception("Failed to load houses for zone $zoneId");
  }

  Future<List<Map<String, dynamic>>> getComplaintCategories() async {
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/complaint/categories');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data.map((x) => Map<String, dynamic>.from(x)));
        }
      }
    } catch (e) {
      debugPrint("Error fetching complaint categories: $e");
    }
    return [
      {"categoryId": "CAT_OVERFLOW", "categoryName": "Garbage Overflow"},
      {"categoryId": "CAT_MISSED", "categoryName": "Missed Collection"},
      {"categoryId": "CAT_DAMAGE", "categoryName": "Damaged Bin"},
      {"categoryId": "CAT_HAZARDOUS", "categoryName": "Hazardous Material"},
      {"categoryId": "CAT_OTHER", "categoryName": "Other Issues"},
    ];
  }

  Future<bool> postComplaint({
    required String workerId,
    required String houseId,
    required String category,
    required String description,
    String? photoUrl,
  }) async {
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/complaint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workerId': workerId,
          'houseId': houseId,
          'category': category,
          'description': description,
          'photoUrl': photoUrl ?? '',
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("Error posting complaint: $e");
    }
    return false;
  }

  Future<void> _fetchAssignedAreaDetails() async {
    if (_workerId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/collection-area/$_workerId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> houses = data['houses'] ?? [];
          setState(() {
            _assignedWardName = "Zone: ${data['zoneId'] ?? ''}";
            _assignedTotalHouseCount = data['totalHouses'] ?? houses.length;
            _houseManifestList.clear();
            for (var h in houses) {
              _houseManifestList.add({
                'registeredUserId': h['registeredUserId'] ?? '',
                'houseNo': h['houseNumber'] ?? '',
                'wardNo': h['wardNumber'] ?? 0,
                'owner': h['ownerName'] ?? '',
                'paymentStatus': (h['paymentStatus'] as String).toLowerCase() == 'paid' ? 'Paid' : 'Pending',
                'feeAmount': (h['amountPending'] as num?)?.toDouble() ?? 0.0,
                'collectStatus': _capitalize(h['collectionStatus'] ?? 'Pending'),
              });
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching worker area: $e");
    }
    setState(() {
      _isLoading = false;
    });
    _showSnackBar("⚠️ Failed to load assigned collection area from server.");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Deletes user profile configurations securely across Spring Boot backend services
  Future<void> _deleteAccountBackendCall() async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return;
    }
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/delete-account');
      await http.delete(url);
    } catch (_) {}
  }

  /// Clears active notification streams from cloud database registers
  Future<void> _clearNotificationsBackendCall() async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    try {
      final url = Uri.parse(
        'http://10.181.174.87:8081/api/worker/clear-notifications',
      );
      await http.post(url);
    } catch (_) {}
  }

  /// Submits dynamic worker leave parameters to centralized Spring Boot backend
  Future<bool> _submitLeaveToBackend(String date, String reason) async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }
    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/leave/request');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workerId': _workerId.trim(),
          'leaveDate': date,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return true;
        } else {
          _showSnackBar("⚠️ Leave request failed: ${data['message']}");
          return false;
        }
      } else {
        _showSnackBar("⚠️ Server error (${response.statusCode}). Please contact Admin.");
        return false;
      }
    } catch (e) {
      debugPrint("Error submitting leave: $e");
      _showSnackBar("⚠️ Connection failure. Leave request not sent.");
      return false;
    }
  }

  /// Updates status configurations securely across Spring Boot backend services
  Future<void> _syncCollectionStatusToBackend(
    String houseNo,
    String status, {
    String exceptionReason = "",
  }) async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    try {
      final url = Uri.parse(
        'http://10.181.174.87:8081/api/worker/update-collect-status',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'houseNo': houseNo,
          'collectStatus': status,
          'exceptionReason': exceptionReason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  /// Sends the complete end-of-day revenue, metric balances, and expense reports to the server
  Future<void> _submitDayReportAndExpenses() async {
    // 1. House lifted validation
    final int? housesLifted = int.tryParse(_collectedCountController.text);
    if (housesLifted == null || housesLifted < 0 || housesLifted > _assignedTotalHouseCount) {
      _showSnackBar("⚠️ Houses Lifted must be a valid number between 0 and $_assignedTotalHouseCount.");
      return;
    }

    // 2. Cash handled validation
    final double? cashHandled = double.tryParse(_cashReceivedController.text);
    if (cashHandled == null || cashHandled < 0) {
      _showSnackBar("⚠️ Cash Handled must be a valid number.");
      return;
    }

    // 3. Units pending validation
    final int? unitsPending = int.tryParse(_pendingCountController.text);
    int totalPendingInZone = _houseManifestList.where((h) => 
      h['collectStatus'].toString().toLowerCase() == 'pending'
    ).length;
    if (unitsPending == null || unitsPending < 0 || unitsPending > totalPendingInZone) {
      _showSnackBar("⚠️ Units Pending must be a valid number less than or equal to the total pending houses in this zone ($totalPendingInZone).");
      return;
    }

    // 4. Route expense validation (optional field, but must be numeric if entered)
    if (_expenseAmountController.text.trim().isNotEmpty) {
      final double? routeExpense = double.tryParse(_expenseAmountController.text);
      if (routeExpense == null || routeExpense < 0) {
        _showSnackBar("⚠️ Route Expense must be a valid number.");
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Synchronizing operations context data with head office database... 📦',
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      try {
        final url = Uri.parse(
          'http://10.181.174.87:8081/api/worker/submit-route-report',
        );
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'wardName': _assignedWardName,
            'housesCollected': _collectedCountController.text,
            'cashAmountReceived': _cashReceivedController.text,
            'remittanceType': _selectedPaymentVectorOption,
            'pendingUnits': _pendingCountController.text,
            'pendingReason': _pendingReasonController.text,
            'expenseReported': _expenseAmountController.text,
            'incidentLog': _incidentReportController.text,
          }),
        );

        final double expenseAmt = double.tryParse(_expenseAmountController.text) ?? 0.0;
        if (expenseAmt > 0) {
          final expenseUrl = Uri.parse('http://10.181.174.87:8081/api/worker/expense');
          final String payMethod = _selectedPaymentVectorOption.toLowerCase().contains("online") ? "online" : "cash";
          final double cashAmt = double.tryParse(_cashReceivedController.text) ?? 0.0;
          await http.post(
            expenseUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'workerId': _workerId,
              'amount': expenseAmt,
              'image': _expenseMockImageBase64,
              'report': 'Day Report: ${_collectedCountController.text} collected, ${_pendingCountController.text} pending (${_pendingReasonController.text})',
              'paymentMethod': payMethod,
              'cashCollected': cashAmt,
            }),
          );
        }
      } catch (_) {}
    }

    setState(() {
      _expenseMockImageBase64 = "";
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✓ System synchronized! Operational logs committed successfully.',
            style: TextStyle(
              color: Color(0xFF020617),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the interactive profile dialog sheet popup with all native options
  void _openUserProfilePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_workerName Profile Context",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            "Verified Crew Lead profile node",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      border: Border.all(color: const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow("Worker ID", _workerId.isNotEmpty ? _workerId : "N/A"),
                        _buildDetailRow("Scheduled Zone", _scheduledZoneName.isNotEmpty ? _scheduledZoneName : "N/A"),
                        _buildDetailRow("Ward Number", _wardNumber > 0 ? _wardNumber.toString() : "N/A"),
                        _buildDetailRow("Village/Area", _villageName.isNotEmpty ? _villageName : "N/A"),
                        _buildDetailRow("Assigned Houses", _numberOfHouses > 0 ? _numberOfHouses.toString() : "N/A"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF10B981),
                    ),
                    title: const Text(
                      "View Shift Notifications",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "${_notifications.length} active logs found",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    onTap: () {
                      _showNotificationsDialog(context, setPanelState);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: Color(0xFFF43F5E),
                    ),
                    title: const Text(
                      "Request Account Deletion",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDA4AF),
                      ),
                    ),
                    subtitle: const Text(
                      "Permanent removal handshake sequence",
                      style: TextStyle(fontSize: 10, color: Color(0xFFFDA4AF)),
                    ),
                    onTap: () {
                      _showDeleteAccountWarning(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFF64748B),
                    ),
                    title: const Text(
                      "Log Out securely",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => EcoBinLoginPage(
                            userDashboardScreen: EcoBinHomePage(),
                            workerDashboardScreen: CollectionWorkerPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsDialog(
    BuildContext parentContext,
    StateSetter setPanelState,
  ) {
    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppCustomAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Shift Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _clearNotificationsBackendCall();
                      setState(() {
                        _notifications.clear();
                      });
                      setDialogState(() {});
                      setPanelState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Notifications cleared successfully. 🧹",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Clear All",
                      style: TextStyle(
                        color: Color(0xFFF43F5E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 300),
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No new system logs detected.",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF1E293B)),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _notifications[index],
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountWarning(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Delete Account permanently?",
          style: TextStyle(
            color: Color(0xFFF43F5E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete the Account permanently? This action cannot be undone and will sever database linkages.",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
            ),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(parentContext);
              await _deleteAccountBackendCall();
              _showSecureDeletionResponseDialog();
            },
            child: const Text(
              "Delete Account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecureDeletionResponseDialog() {
    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Request Submitted",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Your account deletion request has been registered and sent to the server. This request will be checked by our Office.",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF020617),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => EcoBinLoginPage(
                    userDashboardScreen: EcoBinHomePage(),
                    workerDashboardScreen: CollectionWorkerPage(),
                  ),
                ),
              );
            },
            child: const Text(
              "Confirm & Logout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchScheduleAndShowDialog() async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      _showScheduleDetailDialog({
        "status": "success",
        "assignedZoneId": "Zone A",
        "assignedPanchayath": "Grama Panchayath 12",
        "leaveRequestedDate": "2026-06-15",
        "assignedDates": ["2026-06-10", "2026-06-12", "2026-06-14"],
        "wardNumbers": [12, 14, 15]
      });
      return;
    }

    if (_workerId.isEmpty) {
      _showSnackBar("⚠️ Worker identity not verified. Please log in again.");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/worker/schedule/$_workerId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _showScheduleDetailDialog(data);
          return;
        } else {
          _showSnackBar("⚠️ No active schedule found on server: ${data['message'] ?? ''}");
        }
      } else {
        _showSnackBar("⚠️ Failed to load schedule. Server status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("⚠️ Connection error fetching schedule.");
    }
  }

  void _showScheduleDetailDialog(Map<String, dynamic> scheduleData) {
    final List<dynamic> dates = scheduleData['assignedDates'] ?? [];
    final String zone = scheduleData['assignedZoneId'] ?? 'N/A';
    String panchayath = scheduleData['assignedPanchayath'] ?? 'N/A';
    if (panchayath == 'N/A' || panchayath.trim().isEmpty) {
      final matchingAssignment = _assignments.firstWhere(
        (a) => a['zoneId'] == zone,
        orElse: () => <String, dynamic>{},
      );
      if (matchingAssignment.isNotEmpty) {
        panchayath = matchingAssignment['localBodyName'] ?? 'N/A';
      }
    }
    final String leaveDate = scheduleData['leaveRequestedDate'] ?? 'None';
    final List<dynamic> wardNumbers = scheduleData['wardNumbers'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Duty Schedule Grid",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Assigned sectors & dates",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 380),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ASSIGNED ZONE",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Zone: $zone",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Panchayath/Municipality: $panchayath (Wards: ${wardNumbers.isNotEmpty ? wardNumbers.join(', ') : 'N/A'})",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 8),
                      const Text(
                        "📅 LEAVE STATUS",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leaveDate.isNotEmpty && leaveDate != "null"
                            ? "Approved Leave: $leaveDate"
                            : "No approved leaves active",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ASSIGNED DATES FOR COLLECTION",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                dates.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          "No specific collection dates scheduled.",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dates.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Color(0xFF1E293B)),
                        itemBuilder: (context, index) {
                          final dateItem = dates[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF10B981),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateItem.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFCBD5E1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  "Scheduled",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close Schedule View",
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveModal() {
    _leaveDateController.clear();
    _leaveReasonController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppCustomAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Apply Operational Leave",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Submit leave parameter request",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TARGET DATE REQUESTED",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _leaveDateController,
                readOnly: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Select Date (YYYY-MM-DD)",
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  fillColor: const Color(0xFF020617),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF10B981),
                            onPrimary: Color(0xFF020617),
                            surface: Color(0xFF0F172A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _leaveDateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "REASON FOR LEAVE",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _leaveReasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "e.g. Medical issue, personal commitment...",
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  fillColor: const Color(0xFF020617),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                if (_leaveDateController.text.isEmpty ||
                    _leaveReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please complete leave parameters!"),
                    ),
                  );
                  return;
                }
                final String targetDate = _leaveDateController.text;
                final String reasonStr = _leaveReasonController.text.trim();
                Navigator.pop(context);

                final bool success = await _submitLeaveToBackend(targetDate, reasonStr);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✓ Leave request for $targetDate sent to office database! 📅",
                        style: const TextStyle(
                          color: Color(0xFF020617),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Submit Leave Application",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHouseProcessingOverlay(int index) {
    final house = _houseManifestList[index];
    final TextEditingController otpInputController = TextEditingController();
    bool cashCollectedInternalFlag = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AppCustomAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "House Node: ${house['houseNo']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Owner: ${house['owner']}",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (house['paymentStatus'] == 'Pending') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⚠️ ARREARS DUE: ₹${house['feeAmount']}",
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              "Payment Collected in Cash",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              "Mark if cash is received at doorstep",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                            value: cashCollectedInternalFlag,
                            activeColor: const Color(0xFF10B981),
                            checkColor: const Color(0xFF020617),
                            onChanged: (val) {
                              setModalState(() {
                                cashCollectedInternalFlag = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "✓ Fees Paid Online",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "SECURE AUTHENTICATION OTP",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: otpInputController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "• • • •",
                      hintStyle: const TextStyle(
                        color: Color(0xFF334155),
                        letterSpacing: 4,
                      ),
                      fillColor: const Color(0xFF020617),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _handleSkippedLiftAction(index, fromDialog: true),
                child: const Text(
                  "Skip / Exception",
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF020617),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final otp = otpInputController.text.trim();
                  if (otp.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter validation OTP.")),
                    );
                    return;
                  }
                  Navigator.pop(context); // Close the dialog
                  
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final response = await http.post(
                      Uri.parse('http://10.181.174.87:8081/api/collection/verify-otp'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'houseUserId': house['registeredUserId'] ?? '',
                        'otp': otp,
                        'paymentReceivedAtDoor': cashCollectedInternalFlag,
                      }),
                    );
                    if (response.statusCode == 200) {
                      final Map<String, dynamic> resData = jsonDecode(response.body);
                      if (resData['status'] == 'success') {
                        _showSnackBar("✓ Waste collection completed successfully!");
                        await _fetchAssignedAreaDetails();
                      } else {
                        _showSnackBar("❌ Verification failed: ${resData['message'] ?? 'Invalid OTP'}");
                      }
                    } else {
                      _showSnackBar("❌ Server verification failed (Status: ${response.statusCode})");
                    }
                  } catch (e) {
                    _showSnackBar("❌ Network error verifying OTP. Please try again.");
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text(
                  "Verify & Collect",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSkippedLiftAction(int index, {bool fromDialog = false}) {
    if (fromDialog) {
      Navigator.pop(context);
    }
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Log Collection Exception",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: "e.g. Bin empty, Access blocked, Hazardous material",
            hintStyle: TextStyle(color: Color(0xFF475569)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() {
                _houseManifestList[index]['collectStatus'] = "Skipped";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "House ${_houseManifestList[index]['houseNo']} skipped.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF43F5E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              await _syncCollectionStatusToBackend(
                _houseManifestList[index]['houseNo'],
                "Skipped",
                exceptionReason: reasonController.text.trim(),
              );
            },
            child: const Text(
              "Log Exception",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppHeaderRow(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActiveDeploymentCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'FIELD OPERATION MODULES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOperationNavigationRow(),
                    const SizedBox(height: 24),
                    _buildAssignmentsSection(),
                    const SizedBox(height: 24),
                    if (_showCollectionUpdate) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'LIVE UNIT MANIFEST TRACKING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Today Route',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildManifestListViewBlock(),
                      const SizedBox(height: 24),
                    ],
                    _buildRemittanceReportingSection(),
                    const SizedBox(height: 24),
                    _buildIncidentLoggerSection(),
                    const SizedBox(height: 24),
                    _buildFeedbackEvaluationSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBarWidget(),
    );
  }

  Widget _buildAppHeaderRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  text: 'Eco',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
                'OPERATIONS GATEWAY',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _openUserProfilePanel(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(4).copyWith(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: Text(
                      _workerName.length >= 2
                          ? _workerName.substring(0, 2).toUpperCase()
                          : _workerName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CREW LEAD',
                        style: TextStyle(
                          fontSize: 7,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _workerName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ASSIGNED WASTE-COLLECTION AREAS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        if (_assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border.all(color: const Color(0xFF1E293B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "No assigned areas found.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final area = _assignments[index];
              final String zoneId = area['zoneId'] ?? 'N/A';
              final String zoneName = (area['zoneName'] != null && area['zoneName'].toString().isNotEmpty && area['zoneName'] != 'Unnamed Zone')
                  ? area['zoneName']
                  : zoneId;
              
              String address = area['address'] ?? 'No Address';
              if (address == 'No Address' && area['localBodyName'] != null) {
                final String localBody = area['localBodyName'];
                final List<dynamic>? wardNumbers = area['wardNumbers'];
                if (wardNumbers != null && wardNumbers.isNotEmpty) {
                  address = "$localBody (Ward ${wardNumbers.join(', ')})";
                } else {
                  address = localBody;
                }
              }
              
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ZoneHousesDetailScreen(
                        zoneId: zoneId,
                        zoneName: zoneName,
                        workerId: _workerId,
                        getHousesCallback: getHouses,
                        getComplaintCategoriesCallback: getComplaintCategories,
                        postComplaintCallback: postComplaint,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zoneName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF10B981),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          zoneId,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActiveDeploymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE DISPATCHED ASSIGNMENT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'Shift AM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
          Text(
            _assignedWardName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (_nextAssignedDate.isNotEmpty && _nextAssignedDate != "No upcoming date") ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFFCCFBF1),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  "Next Collection: $_nextAssignedDate",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCCFBF1),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDispatchStatColumn(
                "LOAD METRIC",
                "$_assignedTotalHouseCount Houses",
              ),
              _buildDispatchStatColumn("DUTY CLASS", "Main Area Shift"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStatColumn(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF99F6E4),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationNavigationRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickOpButton(
            Icons.alt_route_rounded,
            "View Schedule",
            const Color(0xFF10B981),
            _fetchScheduleAndShowDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickOpButton(
            Icons.fact_check_rounded,
            "Collection Update",
            const Color(0xFF06B6D4),
            () async {
              setState(() {
                _showCollectionUpdate = !_showCollectionUpdate;
              });
              if (_showCollectionUpdate) {
                final String targetZoneId = _scheduledZoneName.isNotEmpty
                    ? _scheduledZoneName
                    : (_assignments.isNotEmpty ? _assignments[0]['zoneId'] ?? '' : '');
                if (targetZoneId.isNotEmpty) {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    final housesList = await getHouses(targetZoneId);
                    setState(() {
                      _houseManifestList.clear();
                      for (var h in housesList) {
                        _houseManifestList.add({
                          'registeredUserId': h['registeredUserId'] ?? '',
                          'houseNo': h['houseNumber'] ?? h['houseNo'] ?? '',
                          'wardNo': h['wardNumber'] ?? h['wardNo'] ?? 0,
                          'owner': h['ownerName'] ?? h['owner'] ?? '',
                          'paymentStatus': ((h['amountPending'] as num?)?.toDouble() == 0.0 ||
                                            (h['paymentStatus'] as String?)?.toLowerCase() == 'paid' ||
                                            (h['collectionStatus'] as String?)?.toLowerCase() == 'paid' ||
                                            (h['collectionStatus'] as String?)?.toLowerCase() == 'paid_via_points')
                                                ? 'Paid'
                                                : 'Pending',
                          'feeAmount': (h['amountPending'] as num?)?.toDouble() ?? 0.0,
                          'collectStatus': _capitalize(h['collectionStatus'] ?? 'Pending'),
                        });
                      }
                      _assignedTotalHouseCount = housesList.length;
                    });
                  } catch (e) {
                    debugPrint("Error loading zone houses: $e");
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _showCollectionUpdate
                          ? "Live tracking manifest expanded below! 🔍"
                          : "Live tracking manifest minimized.",
                    ),
                    backgroundColor: const Color(0xFF06B6D4),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOpButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestListViewBlock() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _houseManifestList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final house = _houseManifestList[index];
        final bool isCollected = house['collectStatus'] == 'Collected';
        final bool isSkipped = house['collectStatus'] == 'Skipped';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border.all(color: const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "House No: ${house['houseNo']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(house['paymentStatus']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Owner: ${house['owner']}",
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCollected)
                _buildActionCompletedIndicator(
                  Icons.check_circle_rounded,
                  "Lifted",
                  const Color(0xFF10B981),
                )
              else if (isSkipped)
                _buildActionCompletedIndicator(
                  Icons.warning_amber_rounded,
                  "Skipped",
                  const Color(0xFFF43F5E),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: house['paymentStatus'] == 'Paid'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF020617),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openHouseProcessingOverlay(index),
                      child: Text(
                        house['paymentStatus'] == 'Paid'
                            ? 'Process'
                            : 'Collect',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF43F5E),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          _houseManifestList[index]['collectStatus'] = "Skipped";
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "House ${_houseManifestList[index]['houseNo']} skipped.",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: const Color(0xFFF43F5E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        await _syncCollectionStatusToBackend(
                          _houseManifestList[index]['houseNo'],
                          "Skipped",
                          exceptionReason: "Skipped from manifest tracking",
                        );
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPaid = status == 'Paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid ? "PAID" : "PENDING FEES",
        style: TextStyle(
          color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionCompletedIndicator(
    IconData icon,
    String text,
    Color targetColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: targetColor, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: targetColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRemittanceReportingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REPORT & EXPENSE SUBMISSION",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Houses Lifted",
                  _collectedCountController,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Cash Handled (₹)",
                  _cashReceivedController,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "OFFICE REMITTANCE VECTOR",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              border: Border.all(color: const Color(0xFF1E293B)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentVectorOption,
                dropdownColor: const Color(0xFF0F172A),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items:
                    [
                          "Pay as cash in office counter",
                          "Pay online instantly (Digital Settlement)",
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() {
                  _selectedPaymentVectorOption = val!;
                }),
              ),
            ),
          ),
          if (_selectedPaymentVectorOption.contains("online")) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final double cashAmount = double.tryParse(_cashReceivedController.text.trim()) ?? 0.0;
                  if (cashAmount <= 0.0) {
                    _showSnackBar("⚠️ Please enter a valid Cash Handled amount first.");
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(amountToPay: cashAmount),
                    ),
                  );
                },
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: const Text(
                  "Launch Digital Remittance Portal",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Units Pending",
                  _pendingCountController,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Reason for Pending",
                  _pendingReasonController,
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),
          const Text(
            "ROUTE RUNTIME EXPENSE VOUCHER",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Amount (₹)",
                  _expenseAmountController,
                  true,
                  hintStr: "e.g. 350",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _showImageSourceDialog((base64String) {
                      setState(() {
                        _expenseMockImageBase64 = base64String;
                      });
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      border: Border.all(
                        color: _expenseMockImageBase64.isNotEmpty
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E293B),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _expenseMockImageBase64.isNotEmpty
                              ? Icons.check_circle_rounded
                              : Icons.camera_alt_rounded,
                          color: _expenseMockImageBase64.isNotEmpty
                              ? const Color(0xFF10B981)
                              : const Color(0xFF475569),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _expenseMockImageBase64.isNotEmpty
                              ? "Voucher Attached"
                              : "Upload Voucher",
                          style: TextStyle(
                            color: _expenseMockImageBase64.isNotEmpty
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitDayReportAndExpenses,
              child: const Text(
                "Submit Operational Logs & Balances",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldLabelAndInput(
    String title,
    TextEditingController targetCtrl,
    bool numeric, {
    String hintStr = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: targetCtrl,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: hintStr,
              hintStyle: const TextStyle(color: Color(0xFF334155)),
              fillColor: const Color(0xFF020617),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentLoggerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "LOG FIELD INCIDENT / COMPLAINT",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incidentReportController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  "Report route anomalies, public alignment issues, damaged bins etc...",
              hintStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
              ),
              fillColor: const Color(0xFF020617),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              _showImageSourceDialog((base64String) {
                setState(() {
                  _complaintMockImageBase64 = base64String;
                });
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(
                  color: _complaintMockImageBase64.isNotEmpty
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _complaintMockImageBase64.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.add_a_photo_outlined,
                    color: const Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _complaintMockImageBase64.isNotEmpty
                        ? "Photo Attached Successfully"
                        : "Upload Complaint Photo (Optional)",
                    style: TextStyle(
                      color: _complaintMockImageBase64.isNotEmpty
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
                side: const BorderSide(color: Color(0xFF1E293B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final reportStr = _incidentReportController.text.trim();
                if (reportStr.isEmpty) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Synchronizing incident report with backend server... ⏳",
                    ),
                  ),
                );
                try {
                  final url = Uri.parse('http://10.181.174.87:8081/api/complaint/submit');
                  final response = await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'userId': _workerId,
                      'complaintDescription': 'Worker Incident: ' + reportStr,
                      'image': _complaintMockImageBase64,
                    }),
                  );
                  if (response.statusCode == 200) {
                    _incidentReportController.clear();
                    setState(() {
                      _complaintMockImageBase64 = "";
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Incident log successfully flagged for supervisor review 🚨",
                        ),
                      ),
                    );
                  } else {
                    _showSnackBar("❌ Server rejected incident log.");
                  }
                } catch (e) {
                  _showSnackBar("❌ Network error submitting incident.");
                }
              },
              child: const Text(
                "Report Incident to Terminal Control",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackEvaluationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "APP PERFORMANCE FEEDBACK",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final int starScore = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _workerRating = starScore;
                  });
                },
                icon: Icon(
                  starScore <= _workerRating
                      ? Icons.star_rate_rounded
                      : Icons.star_border_rounded,
                  color: starScore <= _workerRating
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _workerRating > 0
                ? "Rating: $_workerRating out of 5 stars!"
                : "Tap stars to evaluate system utility.",
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (_workerRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a star rating first!"),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Submitting performance feedback... ⏳"),
                  ),
                );
                try {
                  final url = Uri.parse('http://10.181.174.87:8081/api/feedback/submit');
                  final response = await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'userId': _workerId,
                      'feedbackDescription': 'Worker rating of system utility',
                      'rating': _workerRating,
                    }),
                  );
                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✓ Performance metric score $_workerRating logged securely! 🌟",
                        ),
                      ),
                    );
                    setState(() {
                      _workerRating = 0;
                    });
                  } else {
                    _showSnackBar("❌ Server rejected feedback submission.");
                  }
                } catch (e) {
                  _showSnackBar("❌ Network error submitting feedback.");
                }
              },
              child: const Text(
                "Submit Feedback Metrics",
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBarWidget() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.8)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.airport_shuttle_rounded),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_rounded, color: Color(0xFFFBBF24)),
            label: 'Apply Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new_rounded),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _showCollectionUpdate = true;
            });
          }
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Expense logs brought to focus!")),
            );
          }
          if (index == 2) {
            _showApplyLeaveModal();
          }
          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EcoBinLoginPage(
                  userDashboardScreen: EcoBinHomePage(),
                  workerDashboardScreen: CollectionWorkerPage(),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class AppCustomAlertDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget>? actions;

  const AppCustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }
}

class ZoneHousesDetailScreen extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final String workerId;
  final Future<List<Map<String, dynamic>>> Function(String) getHousesCallback;
  final Future<List<Map<String, dynamic>>> Function() getComplaintCategoriesCallback;
  final Future<bool> Function({
    required String workerId,
    required String houseId,
    required String category,
    required String description,
    String? photoUrl,
  }) postComplaintCallback;

  const ZoneHousesDetailScreen({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.workerId,
    required this.getHousesCallback,
    required this.getComplaintCategoriesCallback,
    required this.postComplaintCallback,
  });

  @override
  State<ZoneHousesDetailScreen> createState() => _ZoneHousesDetailScreenState();
}

class _ZoneHousesDetailScreenState extends State<ZoneHousesDetailScreen> {
  late Future<List<Map<String, dynamic>>> _housesFuture;

  @override
  void initState() {
    super.initState();
    _housesFuture = widget.getHousesCallback(widget.zoneId);
  }

  void _refreshHouses() {
    setState(() {
      _housesFuture = widget.getHousesCallback(widget.zoneId);
    });
  }

  void _openComplaintModal(Map<String, dynamic> house) async {
    final TextEditingController descController = TextEditingController();
    List<Map<String, dynamic>> categories = [];
    String? selectedCategory;
    bool isSubmitting = false;

    // Fetch categories first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.getComplaintCategoriesCallback(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && categories.isEmpty) {
                  return const AppCustomAlertDialog(
                    title: Text("Loading...", style: TextStyle(color: Colors.white)),
                    content: SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF10B981)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasData && categories.isEmpty) {
                  categories = snapshot.data!;
                  if (categories.isNotEmpty) {
                    selectedCategory = categories[0]['categoryName'];
                  }
                }

                return AppCustomAlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Raise Complaint",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "House: ${house['houseId'] ?? house['houseNo'] ?? 'N/A'}",
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "COMPLAINT CATEGORY",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617),
                            border: Border.all(color: const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              dropdownColor: const Color(0xFF0F172A),
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              items: categories
                                  .map((cat) => DropdownMenuItem<String>(
                                        value: cat['categoryName'],
                                        child: Text(cat['categoryName'] ?? ''),
                                      ))
                                  .toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      setModalState(() {
                                        selectedCategory = val;
                                      });
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "DESCRIPTION",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          enabled: !isSubmitting,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Enter complaint details...",
                            hintStyle: const TextStyle(color: Color(0xFF475569)),
                            fillColor: const Color(0xFF020617),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF020617),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final desc = descController.text.trim();
                              if (desc.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Description is required")),
                                );
                                return;
                              }
                              setModalState(() {
                                isSubmitting = true;
                              });

                              final houseId = house['houseId'] ?? house['houseNo'] ?? '';
                              final success = await widget.postComplaintCallback(
                                workerId: widget.workerId,
                                houseId: houseId,
                                category: selectedCategory ?? 'General',
                                description: desc,
                              );

                              if (!mounted) return;
                              Navigator.pop(context); // Close dialog

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✓ Complaint filed successfully!"),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("❌ Failed to submit complaint. Try again."),
                                    backgroundColor: Color(0xFFF43F5E),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF020617)),
                              ),
                            )
                          : const Text(
                              "Submit",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.zoneName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Zone ID: ${widget.zoneId}",
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshHouses,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _housesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFF43F5E)),
                    const SizedBox(height: 12),
                    Text(
                      "Failed to load houses.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: _refreshHouses,
                      child: const Text("Retry", style: TextStyle(color: Color(0xFF020617))),
                    ),
                  ],
                ),
              ),
            );
          }

          final houses = snapshot.data ?? [];
          if (houses.isEmpty) {
            return const Center(
              child: Text(
                "No houses registered in this zone.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final house = houses[index];
              final String houseId = house['houseId'] ?? house['houseNo'] ?? 'N/A';
              final String houseName = house['houseName'] ?? '';
              final String houseDisplayName = houseName.isNotEmpty ? houseName : houseId;
              final String owner = house['ownerName'] ?? house['owner'] ?? 'Unknown Owner';
              final String address = house['address'] ?? 'No Address';
              final String status = house['status'] ?? house['collectStatus'] ?? 'Pending';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF1E293B)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "House: $houseDisplayName",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (status.toLowerCase() != 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Owner: $owner",
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Address: $address",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E).withOpacity(0.1),
                            foregroundColor: const Color(0xFFFDA4AF),
                            side: const BorderSide(color: Color(0xFFF43F5E)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _openComplaintModal(house),
                          icon: const Icon(Icons.report_problem_outlined, size: 14),
                          label: const Text(
                            "Send Complaint",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'collected':
      case 'paid':
        return const Color(0xFF10B981);
      case 'skipped':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
